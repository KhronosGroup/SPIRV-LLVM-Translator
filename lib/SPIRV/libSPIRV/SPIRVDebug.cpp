//===- SPIRVDebug.cpp - SPIR-V Debug Utility --------------------*- C++ -*-===//
//
//                     The LLVM/SPIRV Translator
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
// Copyright (c) 2014 Advanced Micro Devices, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal with the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimers.
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimers in the documentation
// and/or other materials provided with the distribution.
// Neither the names of Advanced Micro Devices, Inc., nor the names of its
// contributors may be used to endorse or promote products derived from this
// Software without specific prior written permission.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS WITH
// THE SOFTWARE.
//
//===----------------------------------------------------------------------===//
/// \file
///
/// This file defines variables for enabling/disabling SPIR-V debug macro.
///
//===----------------------------------------------------------------------===//

#include "SPIRVDebug.h"

#include "llvm/IR/Verifier.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"

#define DEBUG_TYPE "spirv-regularization"

using namespace SPIRV;

bool SPIRV::SPIRVDbgEnable = false;
SPIRV::SPIRVDbgErrorHandlingKinds SPIRV::SPIRVDbgError =
    SPIRVDbgErrorHandlingKinds::Exit;
bool SPIRV::SPIRVDbgErrorMsgIncludesSourceInfo = true;

namespace SPIRV {
llvm::cl::opt<bool> VerifyRegularizationPasses(
    "spirv-verify-regularize-passes", llvm::cl::init(_SPIRVDBG),
    llvm::cl::desc(
        "Verify module after each pass in LLVM regularization phase"));

void verifyRegularizationPass(llvm::Module &M, const std::string &PassName) {
  if (VerifyRegularizationPasses) {
    std::string Err;
    llvm::raw_string_ostream ErrorOS(Err);
    if (llvm::verifyModule(M, &ErrorOS)) {
      LLVM_DEBUG(llvm::errs()
                 << "Failed to verify module after pass: " << PassName << "\n"
                 << ErrorOS.str());
    }
  }
}
} // namespace SPIRV
