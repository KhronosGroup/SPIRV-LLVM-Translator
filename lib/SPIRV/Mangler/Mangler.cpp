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
#include <algorithm>
#include <string>
#include <sstream>
#include <map>

// According to IA64 name mangling spec,
// builtin vector types should not be substituted
// This is a workaround till this gets fixed in CLang
#define ENABLE_MANGLER_VECTOR_SUBSTITUTION 1

namespace SPIR {

class MangleVisitor: public TypeVisitor {
public:

  MangleVisitor(SPIRversion ver, std::stringstream& s) : TypeVisitor(ver), m_stream(s), seqId(0) {
  }

//
// mangle substitution methods
//
  void mangleSequenceID(unsigned SeqID) {
    if (SeqID == 1)
      m_stream << '0';
    else if (SeqID > 1) {
      std::string bstr;
      std::string charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
      SeqID--;
      bstr.reserve(7);
      for (; SeqID != 0; SeqID /= 36)
        bstr += charset.substr(SeqID % 36, 1);
      std::reverse(bstr.begin(), bstr.end());
      m_stream << bstr;
    }
    m_stream << '_';
  }

  bool mangleSubstitution(const ParamType* type, std::string typeStr) {
    size_t fpos;
    std::stringstream thistypeStr;
    thistypeStr << typeStr;
    if ((fpos = m_stream.str().find(typeStr)) != std::string::npos) {
      const char* nType;
      if (const PointerType* p = SPIR::dyn_cast<PointerType>(type)) {
        if ((nType = mangledPrimitiveStringfromName(p->getPointee()->toString())))
          thistypeStr << nType;
      }
#if defined(ENABLE_MANGLER_VECTOR_SUBSTITUTION)
      else if (const VectorType* pVec = SPIR::dyn_cast<VectorType>(type)) {
        if ((nType = mangledPrimitiveStringfromName(pVec->getScalarType()->toString())))
          thistypeStr << nType;
      }
#endif
      std::map<std::string, unsigned>::iterator I = substitutions.find(thistypeStr.str());
      if (I == substitutions.end())
        return false;

      unsigned SeqID = I->second;
      m_stream << 'S';
      mangleSequenceID(SeqID);
      return true;
    }
    return false;
  }

//
// Visit methods
//
  MangleError visit(const PrimitiveType* t) {
    m_stream << mangledPrimitiveString(t->getPrimitive());
    return MANGLE_SUCCESS;
  }

  MangleError visit(const PointerType* p) {
    size_t fpos = m_stream.str().size();
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
      m_stream << "P" << qualStr;
      // and the pointee type itself.
      me = p->getPointee()->accept(this);
      // The type qualifiers plus a pointee type is a substitutable entity
      if(qualStr.length() > 0)
        substitutions[m_stream.str().substr(fpos + 1)] = seqId++;
      // The complete pointer type is substitutable as well
      substitutions[m_stream.str().substr(fpos)] = seqId++;
    }
    return me;
  }

  MangleError visit(const VectorType* v) {
    size_t index = m_stream.str().size();
    std::stringstream typeStr;
    typeStr << "Dv" << v->getLength() << "_";
    MangleError me = MANGLE_SUCCESS;
#if defined(ENABLE_MANGLER_VECTOR_SUBSTITUTION)
    if (!mangleSubstitution(v, typeStr.str()))
#endif
    {
      m_stream << typeStr.str();
      me = v->getScalarType()->accept(this);
      substitutions[m_stream.str().substr(index)] = seqId++;
    }
    return me;
  }

  MangleError visit(const AtomicType* p) {
    m_stream << "U" << "7_Atomic";
    return p->getBaseType()->accept(this);
  }

  MangleError visit(const BlockType* p) {
    m_stream << "U" << "13block_pointerFv";
    if (p->getNumOfParams() == 0)
      m_stream << "v";
    else
      for (unsigned int i=0; i < p->getNumOfParams(); ++i) {
        MangleError err = p->getParam(i)->accept(this);
        if (err != MANGLE_SUCCESS) {
          return err;
        }
      }
    m_stream << "E";
    return MANGLE_SUCCESS;
  }

  MangleError visit(const UserDefinedType* pTy) {
    std::string name = pTy->toString();
    m_stream << name.size() << name;
    return MANGLE_SUCCESS;
  }

private:

  // Holds the mangled string representing the prototype of the function.
  std::stringstream& m_stream;
  unsigned seqId;
  std::map<std::string, unsigned> substitutions;
};

//
// NameMangler
//
  NameMangler::NameMangler(SPIRversion version):m_spir_version(version) {};

  MangleError NameMangler::mangle(const FunctionDescriptor& fd, std::string& mangledName ) {
    if (fd.isNull()) {
      mangledName.assign(FunctionDescriptor::nullString());
      return MANGLE_NULL_FUNC_DESCRIPTOR;
    }
    std::stringstream ret;
    ret << "_Z" << fd.name.length() << fd.name;
    MangleVisitor visitor(m_spir_version, ret);
    for (unsigned int i=0; i < fd.parameters.size(); ++i) {
      MangleError err = fd.parameters[i]->accept(&visitor);
      if(err == MANGLE_TYPE_NOT_SUPPORTED) {
        mangledName.assign("Type ");
        mangledName.append(fd.parameters[i]->toString());
        mangledName.append(" is not supported in ");
        std::string ver = getSPIRVersionAsString(m_spir_version);
        mangledName.append(ver);
        return err;
      }
    }
    mangledName.assign(ret.str());
    return MANGLE_SUCCESS;
  }

} // End SPIR namespace
