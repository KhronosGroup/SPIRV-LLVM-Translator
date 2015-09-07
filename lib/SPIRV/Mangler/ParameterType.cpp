//===------------------------ ParameterType.cpp --------------------------===//
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
#include "ParameterType.h"
#include "ManglingUtils.h"
#include <assert.h>
#include <cctype>
#include <sstream>

namespace SPIR {
  //
  // Primitive Type
  //

  PrimitiveType::PrimitiveType(TypePrimitiveEnum primitive) :
   ParamType(TYPE_ID_PRIMITIVE), m_primitive(primitive) {
  }


  MangleError PrimitiveType::accept(TypeVisitor* visitor) const {
    if (getSupportedVersion(this->getPrimitive()) >= SPIR20 && visitor->spirVer < SPIR20) {
      return MANGLE_TYPE_NOT_SUPPORTED;
    }
    return visitor->visit(this);
  }

  std::string PrimitiveType::toString() const {
    assert( (m_primitive >= PRIMITIVE_FIRST
      && m_primitive <= PRIMITIVE_LAST) && "illegal primitive");
    std::stringstream myName;
    myName << readablePrimitiveString(m_primitive);
    return myName.str();
  }

  bool PrimitiveType::equals(const ParamType* type) const {
    const PrimitiveType* p = SPIR::dyn_cast<PrimitiveType>(type);
    return p && (m_primitive == p->m_primitive);
  }


  //
  // Pointer Type
  //

  PointerType::PointerType(const RefParamType type) :
    ParamType(TYPE_ID_POINTER), m_pType(type) {
    for (unsigned int i = ATTR_QUALIFIER_FIRST; i <= ATTR_QUALIFIER_LAST; i++) {
      setQualifier((TypeAttributeEnum)i, false);
    }
    m_address_space = ATTR_PRIVATE;
  }

  MangleError PointerType::accept(TypeVisitor* visitor) const {
    return visitor->visit(this);
  }

  void PointerType::setAddressSpace(TypeAttributeEnum attr) {
    if (attr < ATTR_ADDR_SPACE_FIRST || attr > ATTR_ADDR_SPACE_LAST) {
      return;
    }
    m_address_space = attr;
  }

  TypeAttributeEnum PointerType::getAddressSpace() const {
    return m_address_space;
  }

  void PointerType::setQualifier(TypeAttributeEnum qual, bool enabled) {
    if (qual < ATTR_QUALIFIER_FIRST || qual > ATTR_QUALIFIER_LAST) {
      return;
    }
    m_qualifiers[qual - ATTR_QUALIFIER_FIRST] = enabled;
  }

  bool PointerType::hasQualifier(TypeAttributeEnum qual) const {
    if (qual < ATTR_QUALIFIER_FIRST || qual > ATTR_QUALIFIER_LAST) {
      return false;
    }
    return m_qualifiers[qual - ATTR_QUALIFIER_FIRST];
  }

  std::string PointerType::toString() const {
    std::stringstream myName;
    for (unsigned int i = ATTR_QUALIFIER_FIRST; i <= ATTR_QUALIFIER_LAST; i++) {
      TypeAttributeEnum qual = (TypeAttributeEnum)i;
      if (hasQualifier(qual)) {
        myName << getReadableAttribute(qual) << " ";
      }
    }
    myName << getReadableAttribute(TypeAttributeEnum(m_address_space)) << " ";
    myName << getPointee()->toString() << " *";
    return myName.str();
  }

  bool PointerType::equals(const ParamType* type) const {
    const PointerType* p = SPIR::dyn_cast<PointerType>(type);
    if (!p) {
      return false;
    }
    if (getAddressSpace() != p->getAddressSpace()) {
      return false;
    }
    for (unsigned int i = ATTR_QUALIFIER_FIRST; i <= ATTR_QUALIFIER_LAST; i++) {
      TypeAttributeEnum qual = (TypeAttributeEnum)i;
      if (hasQualifier(qual) != p->hasQualifier(qual)) {
        return false;
      }
    }
    return (*getPointee()).equals(&*(p->getPointee()));
  }

  //
  // Vector Type
  //

  VectorType::VectorType(const RefParamType type, int len) :
    ParamType(TYPE_ID_VECTOR), m_pType(type), m_len(len) {
  }

  MangleError VectorType::accept(TypeVisitor* visitor) const {
    return visitor->visit(this);
  }

  std::string VectorType::toString() const {
    std::stringstream myName;
    myName << getScalarType()->toString();
    myName << m_len;
    return myName.str();
  }

  bool VectorType::equals(const ParamType* type) const {
    const VectorType* pVec = SPIR::dyn_cast<VectorType>(type);
    return pVec && (m_len == pVec->m_len) &&
      (*getScalarType()).equals(&*(pVec->getScalarType()));
  }

  //
  //Atomic Type
  //

  AtomicType::AtomicType(const RefParamType type) :
    ParamType(TYPE_ID_ATOMIC), m_pType(type) {
  }

  MangleError AtomicType::accept(TypeVisitor* visitor) const {
    if (visitor->spirVer < SPIR20) {
      return MANGLE_TYPE_NOT_SUPPORTED;
    }
    return visitor->visit(this);
  }

  std::string AtomicType::toString() const {
    std::stringstream myName;
    myName << "U7_Atomic" << getBaseType()->toString();
    return myName.str();
  }

  bool AtomicType::equals(const ParamType* type) const {
    const AtomicType* a = dyn_cast<AtomicType>(type);
    return (a && (*getBaseType()).equals(&*(a->getBaseType())));
  }

  //
  //Block Type
  //

  BlockType::BlockType() :
    ParamType(TYPE_ID_BLOCK) {
  }

  MangleError BlockType::accept(TypeVisitor* visitor) const {
    if (visitor->spirVer < SPIR20) {
      return MANGLE_TYPE_NOT_SUPPORTED;
    }
    return visitor->visit(this);
  }

  std::string BlockType::toString() const {
    std::stringstream myName;
    myName << "void (";
    for (unsigned int i=0; i<getNumOfParams(); ++i) {
      if (i>0) myName << ", ";
      myName << m_params[i]->toString();
    }
    myName << ")*";
    return myName.str();
  }

  bool BlockType::equals(const ParamType* type) const {
    const BlockType* pBlock = dyn_cast<BlockType>(type);
    if (!pBlock || getNumOfParams() != pBlock->getNumOfParams() ) {
      return false;
    }
    for (unsigned int i=0; i<getNumOfParams(); ++i) {
      if (!getParam(i)->equals(&*pBlock->getParam(i))) {
        return false;
      }
    }
    return true;
  }

  //
  // User Defined Type
  //
  UserDefinedType::UserDefinedType(const std::string& name):
    ParamType(TYPE_ID_STRUCTURE), m_name(name) {
  }

  MangleError UserDefinedType::accept(TypeVisitor* visitor) const {
    return visitor->visit(this);
  }

  std::string UserDefinedType::toString() const {
    std::stringstream myName;
    myName << m_name;
    return myName.str();
  }

  bool UserDefinedType::equals(const ParamType* pType) const {
    const UserDefinedType* pTy = SPIR::dyn_cast<UserDefinedType>(pType);
    return pTy && (m_name == pTy->m_name);
  }


  //
  // Static enums
  //
  const TypeEnum PrimitiveType::enumTy    = TYPE_ID_PRIMITIVE;
  const TypeEnum PointerType::enumTy      = TYPE_ID_POINTER;
  const TypeEnum VectorType::enumTy       = TYPE_ID_VECTOR;
  const TypeEnum AtomicType::enumTy       = TYPE_ID_ATOMIC;
  const TypeEnum BlockType::enumTy        = TYPE_ID_BLOCK;
  const TypeEnum UserDefinedType::enumTy  = TYPE_ID_STRUCTURE;

} // End SPIR namespace
