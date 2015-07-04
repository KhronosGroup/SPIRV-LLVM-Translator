//===----------------------- FunctionDescriptor.h ------------------------===//
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

#ifndef __FUNCTION_DESCRIPTOR_H__
#define __FUNCTION_DESCRIPTOR_H__

#include "ParameterType.h"
#include "Refcount.h"
#include <string>
#include <vector>

namespace SPIR {
typedef std::vector<RefCount<ParamType> > TypeVector;

struct FunctionDescriptor {
  /// @brief Returns a human readable string representation of the function's
  ///        prototype.
  /// @returns std::string representing the function's prototype.
  std::string toString() const;

  /// The name of the function (stripped).
  std::string name;
  /// Parameter list of the function.
  TypeVector parameters;

  bool operator == (const FunctionDescriptor&) const;

  /// @brief Enables function descriptors to serve as keys in stl maps.
  bool operator < (const FunctionDescriptor&) const;
  bool isNull() const;

  /// @brief Create a singular value, that represents a 'null' FunctionDescriptor.
  static FunctionDescriptor null();

  static std::string nullString();
};

template <typename T>
std::ostream& operator<< (T& o, const SPIR::FunctionDescriptor& fd) {
  o << fd.toString();
  return o;
}
} // End SPIR namespace

#endif //__FUNCTION_DESCRIPTOR_H__
