//===------------------------- NameMangleAPI.h ---------------------------===//
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
#ifndef __NAME_MANGLE_API_H__
#define __NAME_MANGLE_API_H__

#include "FunctionDescriptor.h"
#include <string>

namespace SPIR {
  struct NameMangler {

    /// @brief Constructor.
    /// @param SPIRversion spir version to mangle according to.
    NameMangler(SPIRversion);

    /// @brief Converts the given function descriptor to string that represents
    ///        the function's prototype.
    ///        The mangling algorithm is based on Itanium mangling algorithm
    ///        (http://sourcery.mentor.com/public/cxx-abi/abi.html#mangling), with
    ///        SPIR extensions.
    /// @param FunctionDescriptor function to be mangled.
    /// @param std::string the mangled name if the mangling succeeds,
    ///        the error otherwise.
    /// @return MangleError enum representing the status - success or the error.
    MangleError mangle(const FunctionDescriptor&, std::string &);
  private:
    SPIRversion m_spir_version;
  };
} // End SPIR namespace

#endif //__NAME_MANGLE_API_H__
