//===------------------------- ManglingUtils.h ---------------------------===//
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

#ifndef SPIRV_MANGLER_MANGLINGUTILS_H
#define SPIRV_MANGLER_MANGLINGUTILS_H

#include "ParameterType.h"

namespace SPIR {

const char *mangledPrimitiveString(TypePrimitiveEnum primitive);
const char *readablePrimitiveString(TypePrimitiveEnum primitive);

const char *getMangledAttribute(TypeAttributeEnum attribute);
const char *getReadableAttribute(TypeAttributeEnum attribute);

SPIRversion getSupportedVersion(TypePrimitiveEnum t);
const char *getSPIRVersionAsString(SPIRversion version);

const char *mangledPrimitiveStringfromName(std::string type);

bool isPipeBuiltin(std::string unmangledName);
} // namespace SPIR

#endif // SPIRV_MANGLER_MANGLINGUTILS_H
