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

PrimitiveType::PrimitiveType(TypePrimitiveEnum primitive)
    : ParamType(TYPE_ID_PRIMITIVE), Primitive(primitive) {}

MangleError PrimitiveType::accept(TypeVisitor *visitor) const {
  if (getSupportedVersion(this->getPrimitive()) >= SPIR20 &&
      visitor->spirVer < SPIR20) {
    return MANGLE_TYPE_NOT_SUPPORTED;
  }
  return visitor->visit(this);
}

std::string PrimitiveType::toString() const {
  assert((Primitive >= PRIMITIVE_FIRST && Primitive <= PRIMITIVE_LAST) &&
         "illegal primitive");
  std::stringstream myName;
  myName << readablePrimitiveString(Primitive);
  return myName.str();
}

bool PrimitiveType::equals(const ParamType *type) const {
  const PrimitiveType *p = SPIR::dyn_cast<PrimitiveType>(type);
  return p && (Primitive == p->Primitive);
}

//
// Pointer Type
//

PointerType::PointerType(const RefParamType type)
    : ParamType(TYPE_ID_POINTER), PType(type) {
  for (unsigned int i = ATTR_QUALIFIER_FIRST; i <= ATTR_QUALIFIER_LAST; i++) {
    setQualifier((TypeAttributeEnum)i, false);
  }
  Address_space = ATTR_PRIVATE;
}

MangleError PointerType::accept(TypeVisitor *visitor) const {
  return visitor->visit(this);
}

void PointerType::setAddressSpace(TypeAttributeEnum attr) {
  if (attr < ATTR_ADDR_SPACE_FIRST || attr > ATTR_ADDR_SPACE_LAST) {
    return;
  }
  Address_space = attr;
}

TypeAttributeEnum PointerType::getAddressSpace() const {
  return Address_space;
}

void PointerType::setQualifier(TypeAttributeEnum qual, bool enabled) {
  if (qual < ATTR_QUALIFIER_FIRST || qual > ATTR_QUALIFIER_LAST) {
    return;
  }
  Qualifiers[qual - ATTR_QUALIFIER_FIRST] = enabled;
}

bool PointerType::hasQualifier(TypeAttributeEnum qual) const {
  if (qual < ATTR_QUALIFIER_FIRST || qual > ATTR_QUALIFIER_LAST) {
    return false;
  }
  return Qualifiers[qual - ATTR_QUALIFIER_FIRST];
}

std::string PointerType::toString() const {
  std::stringstream myName;
  for (unsigned int i = ATTR_QUALIFIER_FIRST; i <= ATTR_QUALIFIER_LAST; i++) {
    TypeAttributeEnum qual = (TypeAttributeEnum)i;
    if (hasQualifier(qual)) {
      myName << getReadableAttribute(qual) << " ";
    }
  }
  myName << getReadableAttribute(TypeAttributeEnum(Address_space)) << " ";
  myName << getPointee()->toString() << " *";
  return myName.str();
}

bool PointerType::equals(const ParamType *type) const {
  const PointerType *p = SPIR::dyn_cast<PointerType>(type);
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

VectorType::VectorType(const RefParamType type, int len)
    : ParamType(TYPE_ID_VECTOR), PType(type), Len(len) {}

MangleError VectorType::accept(TypeVisitor *visitor) const {
  return visitor->visit(this);
}

std::string VectorType::toString() const {
  std::stringstream myName;
  myName << getScalarType()->toString();
  myName << Len;
  return myName.str();
}

bool VectorType::equals(const ParamType *type) const {
  const VectorType *pVec = SPIR::dyn_cast<VectorType>(type);
  return pVec && (Len == pVec->Len) &&
         (*getScalarType()).equals(&*(pVec->getScalarType()));
}

//
// Atomic Type
//

AtomicType::AtomicType(const RefParamType type)
    : ParamType(TYPE_ID_ATOMIC), PType(type) {}

MangleError AtomicType::accept(TypeVisitor *visitor) const {
  if (visitor->spirVer < SPIR20) {
    return MANGLE_TYPE_NOT_SUPPORTED;
  }
  return visitor->visit(this);
}

std::string AtomicType::toString() const {
  std::stringstream myName;
  myName << "atomic_" << getBaseType()->toString();
  return myName.str();
}

bool AtomicType::equals(const ParamType *type) const {
  const AtomicType *a = dyn_cast<AtomicType>(type);
  return (a && (*getBaseType()).equals(&*(a->getBaseType())));
}

//
// Block Type
//

BlockType::BlockType() : ParamType(TYPE_ID_BLOCK) {}

MangleError BlockType::accept(TypeVisitor *visitor) const {
  if (visitor->spirVer < SPIR20) {
    return MANGLE_TYPE_NOT_SUPPORTED;
  }
  return visitor->visit(this);
}

std::string BlockType::toString() const {
  std::stringstream myName;
  myName << "void (";
  for (unsigned int i = 0; i < getNumOfParams(); ++i) {
    if (i > 0)
      myName << ", ";
    myName << Params[i]->toString();
  }
  myName << ")*";
  return myName.str();
}

bool BlockType::equals(const ParamType *type) const {
  const BlockType *pBlock = dyn_cast<BlockType>(type);
  if (!pBlock || getNumOfParams() != pBlock->getNumOfParams()) {
    return false;
  }
  for (unsigned int i = 0; i < getNumOfParams(); ++i) {
    if (!getParam(i)->equals(&*pBlock->getParam(i))) {
      return false;
    }
  }
  return true;
}

//
// User Defined Type
//
UserDefinedType::UserDefinedType(const std::string &name)
    : ParamType(TYPE_ID_STRUCTURE), Name(name) {}

MangleError UserDefinedType::accept(TypeVisitor *visitor) const {
  return visitor->visit(this);
}

std::string UserDefinedType::toString() const {
  std::stringstream myName;
  myName << Name;
  return myName.str();
}

bool UserDefinedType::equals(const ParamType *pType) const {
  const UserDefinedType *pTy = SPIR::dyn_cast<UserDefinedType>(pType);
  return pTy && (Name == pTy->Name);
}

//
// Static enums
//
const TypeEnum PrimitiveType::enumTy = TYPE_ID_PRIMITIVE;
const TypeEnum PointerType::enumTy = TYPE_ID_POINTER;
const TypeEnum VectorType::enumTy = TYPE_ID_VECTOR;
const TypeEnum AtomicType::enumTy = TYPE_ID_ATOMIC;
const TypeEnum BlockType::enumTy = TYPE_ID_BLOCK;
const TypeEnum UserDefinedType::enumTy = TYPE_ID_STRUCTURE;

} // namespace SPIR
