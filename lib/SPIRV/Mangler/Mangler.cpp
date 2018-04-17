//===--------------------------- Mangler.cpp -----------------------------===//
//
//                              SPIR Tools
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===---------------------------------------------------------------------===//
/*
 * Contributed by: Intel Corporation.
 */

#include "FunctionDescriptor.h"
#include "ManglingUtils.h"
#include "NameMangleAPI.h"
#include "ParameterType.h"
#include "SPIRVInternal.h"
#include <algorithm>
#include <map>
#include <sstream>
#include <string>

// According to IA64 name mangling spec,
// builtin vector types should not be substituted
// This is a workaround till this gets fixed in CLang
#define ENABLE_MANGLER_VECTOR_SUBSTITUTION 1

namespace SPIR {

class MangleVisitor : public TypeVisitor {
public:
  MangleVisitor(SPIRversion ver, std::stringstream &s)
      : TypeVisitor(ver), Stream(s), seqId(0) {}

  //
  // mangle substitution methods
  //
  void mangleSequenceID(unsigned SeqID) {
    if (SeqID == 1)
      Stream << '0';
    else if (SeqID > 1) {
      std::string bstr;
      std::string charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
      SeqID--;
      bstr.reserve(7);
      for (; SeqID != 0; SeqID /= 36)
        bstr += charset.substr(SeqID % 36, 1);
      std::reverse(bstr.begin(), bstr.end());
      Stream << bstr;
    }
    Stream << '_';
  }

  bool mangleSubstitution(const ParamType *type, std::string typeStr) {
    size_t fpos;
    std::stringstream thistypeStr;
    thistypeStr << typeStr;
    if ((fpos = Stream.str().find(typeStr)) != std::string::npos) {
      const char *nType;
      if (const PointerType *p = SPIR::dyn_cast<PointerType>(type)) {
        if ((nType =
                 mangledPrimitiveStringfromName(p->getPointee()->toString())))
          thistypeStr << nType;
      }
#if defined(ENABLE_MANGLER_VECTOR_SUBSTITUTION)
      else if (const VectorType *pVec = SPIR::dyn_cast<VectorType>(type)) {
        if ((nType = mangledPrimitiveStringfromName(
                 pVec->getScalarType()->toString())))
          thistypeStr << nType;
      }
#endif
      std::map<std::string, unsigned>::iterator I =
          substitutions.find(thistypeStr.str());
      if (I == substitutions.end())
        return false;

      unsigned SeqID = I->second;
      Stream << 'S';
      mangleSequenceID(SeqID);
      return true;
    }
    return false;
  }

  //
  // Visit methods
  //
  MangleError visit(const PrimitiveType *t) override {
    MangleError me = MANGLE_SUCCESS;
#if defined(SPIRV_SPIR20_MANGLING_REQUIREMENTS)
    Stream << mangledPrimitiveString(t->getPrimitive());
#else
    std::string mangledPrimitive =
        std::string(mangledPrimitiveString(t->getPrimitive()));
    // out of all enums it makes sense to substitute only
    // memory_scope/memory_order since only they appear several times in the
    // builtin declaration.
    if (mangledPrimitive == "12memory_scope" ||
        mangledPrimitive == "12memory_order") {
      if (!mangleSubstitution(t, mangledPrimitiveString(t->getPrimitive()))) {
        size_t index = Stream.str().size();
        Stream << mangledPrimitiveString(t->getPrimitive());
        substitutions[Stream.str().substr(index)] = seqId++;
      }
    } else {
      Stream << mangledPrimitive;
    }
#endif
    return me;
  }

  MangleError visit(const PointerType *p) override {
    size_t fpos = Stream.str().size();
    std::string qualStr;
    MangleError me = MANGLE_SUCCESS;
    for (unsigned int i = ATTR_QUALIFIER_FIRST; i <= ATTR_QUALIFIER_LAST; i++) {
      TypeAttributeEnum qualifier = (TypeAttributeEnum)i;
      if (p->hasQualifier(qualifier)) {
        qualStr += getMangledAttribute(qualifier);
      }
    }
    qualStr += getMangledAttribute((p->getAddressSpace()));
    if (!mangleSubstitution(p, "P" + qualStr)) {
      // A pointee type is substituted when it is a user type, a vector type
      // (but see a comment in the beginning of this file), a pointer type,
      // or a primitive type with qualifiers (addr. space and/or CV qualifiers).
      // So, stream "P", type qualifiers
      Stream << "P" << qualStr;
      // and the pointee type itself.
      me = p->getPointee()->accept(this);
      // The type qualifiers plus a pointee type is a substitutable entity
      if (qualStr.length() > 0)
        substitutions[Stream.str().substr(fpos + 1)] = seqId++;
      // The complete pointer type is substitutable as well
      substitutions[Stream.str().substr(fpos)] = seqId++;
    }
    return me;
  }

  MangleError visit(const VectorType *v) override {
    size_t index = Stream.str().size();
    std::stringstream typeStr;
    typeStr << "Dv" << v->getLength() << "_";
    MangleError me = MANGLE_SUCCESS;
#if defined(ENABLE_MANGLER_VECTOR_SUBSTITUTION)
    if (!mangleSubstitution(v, typeStr.str()))
#endif
    {
      Stream << typeStr.str();
      me = v->getScalarType()->accept(this);
      substitutions[Stream.str().substr(index)] = seqId++;
    }
    return me;
  }

  MangleError visit(const AtomicType *p) override {
    MangleError me = MANGLE_SUCCESS;
    size_t index = Stream.str().size();
    const char *typeStr = "U7_Atomic";
    if (!mangleSubstitution(p, typeStr)) {
      Stream << typeStr;
      me = p->getBaseType()->accept(this);
      substitutions[Stream.str().substr(index)] = seqId++;
    }
    return me;
  }

  MangleError visit(const BlockType *p) override {
    Stream << "U"
             << "13block_pointerFv";
    if (p->getNumOfParams() == 0)
      Stream << "v";
    else
      for (unsigned int i = 0; i < p->getNumOfParams(); ++i) {
        MangleError err = p->getParam(i)->accept(this);
        if (err != MANGLE_SUCCESS) {
          return err;
        }
      }
    Stream << "E";
    return MANGLE_SUCCESS;
  }

  MangleError visit(const UserDefinedType *pTy) override {
    std::string name = pTy->toString();
    Stream << name.size() << name;
    return MANGLE_SUCCESS;
  }

private:
  // Holds the mangled string representing the prototype of the function.
  std::stringstream &Stream;
  unsigned seqId;
  std::map<std::string, unsigned> substitutions;
};

//
// NameMangler
//
NameMangler::NameMangler(SPIRversion version) : Spir_version(version) {}

MangleError NameMangler::mangle(const FunctionDescriptor &fd,
                                std::string &mangledName) {
  if (fd.isNull()) {
    mangledName.assign(FunctionDescriptor::nullString());
    return MANGLE_NULL_FUNC_DESCRIPTOR;
  }
  std::stringstream ret;
  ret << "_Z" << fd.name.length() << fd.name;
  MangleVisitor visitor(Spir_version, ret);
  for (unsigned int i = 0; i < fd.parameters.size(); ++i) {
    MangleError err = fd.parameters[i]->accept(&visitor);
    if (err == MANGLE_TYPE_NOT_SUPPORTED) {
      mangledName.assign("Type ");
      mangledName.append(fd.parameters[i]->toString());
      mangledName.append(" is not supported in ");
      std::string ver = getSPIRVersionAsString(Spir_version);
      mangledName.append(ver);
      return err;
    }
  }
  mangledName.assign(ret.str());
  return MANGLE_SUCCESS;
}

} // namespace SPIR
