//===- SPIRVOptsC.h - Specify options for translation -------------*- C -*-===//
//
//                     The LLVM/SPIRV Translator
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
// Copyright (c) 2020 Julia Computing. All rights reserved.
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
/// \file SPIRVOptsC.h
///
/// This files implements the C API to handle SPIR-V versions and extensions.
///
//===----------------------------------------------------------------------===//

#include "LLVMSPIRVOpts.h"
#include "LLVMSPIRVOptsC.h"

using namespace SPIRV;
using namespace llvm;

SPIRVTranslatorOptsRef LLVMCreateDefaultTranslatorOpts() {
  return wrap(new TranslatorOpts());
}

SPIRVTranslatorOptsRef LLVMCreateTranslatorOpts(SPIRVVersionNumber Version,
                                                SPIRVExtensionID *Extensions,
                                                unsigned NumExtensions) {
  TranslatorOpts::ExtensionsStatusMap Map;
  for (int i = 0; i < NumExtensions; i++)
    Map[unwrap(Extensions[i])] = true;
  return wrap(new TranslatorOpts(unwrap(Version), Map));
}

LLVMBool
LLVMTranslatorOptsIsAllowedToUseVersion(SPIRVTranslatorOptsRef Opts,
                                        SPIRVVersionNumber RequestedVersion) {
  return unwrap(Opts)->isAllowedToUseVersion(unwrap(RequestedVersion));
}

LLVMBool LLVMTranslatorOptsIsAllowedToUseExtension(SPIRVTranslatorOptsRef Opts,
                                                   SPIRVExtensionID Extension) {
  return unwrap(Opts)->isAllowedToUseExtension(unwrap(Extension));
}

SPIRVVersionNumber
LLVMTranslatorOptsGetMaxVersion(SPIRVTranslatorOptsRef Opts) {
  return wrap(unwrap(Opts)->getMaxVersion());
}

LLVMBool LLVMTranslatorOptsIsGenArgNameMDEnabled(SPIRVTranslatorOptsRef Opts) {
  return unwrap(Opts)->isGenArgNameMDEnabled();
}

LLVMBool LLVMTranslatorOptsIsSPIRVMemToRegEnabled(SPIRVTranslatorOptsRef Opts) {
  return unwrap(Opts)->isSPIRVMemToRegEnabled();
}

void LLVMTranslatorOptsSetMemToRegEnabled(SPIRVTranslatorOptsRef Opts,
                                          LLVMBool Mem2Reg) {
  unwrap(Opts)->setMemToRegEnabled(Mem2Reg);
}

void LLVMTranslatorOptsSetGenKernelArgNameMDEnabled(SPIRVTranslatorOptsRef Opts,
                                                    LLVMBool ArgNameMD) {
  unwrap(Opts)->setGenKernelArgNameMDEnabled(ArgNameMD);
}

void LLVMTranslatorOptsEnableAllExtensions(SPIRVTranslatorOptsRef Opts) {
  unwrap(Opts)->enableAllExtensions();
}

void LLVMTranslatorOptsEnableGenArgNameMD(SPIRVTranslatorOptsRef Opts) {
  unwrap(Opts)->enableGenArgNameMD();
}

void LLVMTranslatorOptsSetSpecConst(SPIRVTranslatorOptsRef Opts,
                                    uint32_t SpecId, uint64_t SpecValue) {
  unwrap(Opts)->setSpecConst(SpecId, SpecValue);
}

LLVMBool
LLVMTranslatorOptsGetSpecializationConstant(SPIRVTranslatorOptsRef Opts,
                                            uint32_t SpecId, uint64_t *Value) {
  uint64_t SpecValue;
  if (unwrap(Opts)->getSpecializationConstant(SpecId, SpecValue)) {
    *Value = SpecValue;
    return true;
  } else {
    return false;
  }
}

void LLVMTranslatorOptsSetDesiredBIsRepresentation(
    SPIRVTranslatorOptsRef Opts, SPIRVBIsRepresentation Value) {
  return unwrap(Opts)->setDesiredBIsRepresentation(unwrap(Value));
}

SPIRVBIsRepresentation
LLVMTranslatorOptsetDesiredBIsRepresentation(SPIRVTranslatorOptsRef Opts) {
  return wrap(unwrap(Opts)->getDesiredBIsRepresentation());
}

void LLVMDisposeTranslatorOpts(SPIRVTranslatorOptsRef Opts) {
  delete unwrap(Opts);
}
