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
#include <string>
#include <sstream>

namespace SPIR {

class MangleVisitor: public TypeVisitor {
public:

  MangleVisitor(SPIRversion ver, std::stringstream& s): TypeVisitor(ver), m_stream(s) {
  }

//
// Visit methods
//
  MangleError visit(const PrimitiveType* t) {
    m_stream << mangledPrimitiveString(t->getPrimitive());
    return MANGLE_SUCCESS;
  }

  MangleError visit(const PointerType* p) {
    m_stream << "P";
    for (unsigned int i = ATTR_QUALIFIER_FIRST; i <= ATTR_QUALIFIER_LAST; i++) {
      TypeAttributeEnum qualifier = (TypeAttributeEnum)i;
      if (p->hasQualifier(qualifier)) {
        m_stream << getMangledAttribute(qualifier);
      }
    }
    m_stream << getMangledAttribute((p->getAddressSpace()));
    return p->getPointee()->accept(this);
  }

  MangleError visit(const VectorType* v) {
    m_stream << "Dv" << v->getLength() << "_";
    return v->getScalarType()->accept(this);
  }

  MangleError visit(const AtomicType* p) {
    m_stream << "U" << "7_Atomic";
    return p->getBaseType()->accept(this);
  }

  MangleError visit(const BlockType* p) {
    m_stream << "U" << "13block_pointerFv";
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
