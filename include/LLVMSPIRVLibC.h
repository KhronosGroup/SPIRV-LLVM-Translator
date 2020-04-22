//===- LLVMSPIRVLibC.h - Read and write SPIR-V binary -------------*- C -*-===//
//
//                     The LLVM Compiler Infrastructure
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
/// \file LLVMSPIRVLibC.h
///
/// This files declares the C API for translating between LLVM and SPIR-V.
///
//===----------------------------------------------------------------------===//
#ifndef SPIRV_C_H
#define SPIRV_C_H

#include "llvm-c/Core.h"
#include "llvm-c/Types.h"

#include "LLVMSPIRVOptsC.h"
#include "LLVMSPIRVTypes.h"

LLVM_C_EXTERN_C_BEGIN

LLVMBool SPIRVIsSpirvBinary(const char *ImgBuf, unsigned ImgLen);

#ifdef _SPIRV_C_SUPPORT_TEXT_FMT

LLVMBool SPIRVIsSpirvText(const char *ImgBuf, unsigned ImgLen);

LLVMBool SPIRVConvertSpirv(const char *InputBuf, unsigned InputLen, char **Out,
                           char **ErrMsg, LLVMBool ToText);

#endif

SPIRVModuleRef SPIRVReadSpirvModule(const char *ImgBuf, unsigned ImgLen,
                                    char **ErrMsg);

SPIRVModuleRef SPIRVReadSpirvModuleWithOpts(const char *ImgBuf, unsigned ImgLen,
                                            SPIRVTranslatorOptsRef Opts,
                                            char **ErrMsg);

LLVMBool LLVMWriteSpirv(LLVMModuleRef M, LLVMMemoryBufferRef *Out,
                        char **ErrMsg);

LLVMBool LLVMReadSpirv(LLVMContextRef C, const char *ImgBuf, unsigned ImgLen,
                       LLVMModuleRef *M, char **ErrMsg);

LLVMBool LLVMWriteSpirvWithOpts(LLVMModuleRef M, SPIRVTranslatorOptsRef Opts,
                                LLVMMemoryBufferRef *Out, char **ErrMsg);

LLVMBool LLVMReadSpirvWithOpts(LLVMContextRef C, SPIRVTranslatorOptsRef Opts,
                               const char *ImgBuf, unsigned ImgLen,
                               LLVMModuleRef *M, char **ErrMsg);

struct SPIRVSpecSpecConstInfoTy {
  uint32_t first;
  uint32_t second;
};
LLVMBool LLVMGetSpecConstInfo(const char *ImgBuf, unsigned ImgLen,
                              SPIRVSpecSpecConstInfoTy **SpecConstInfos,
                              unsigned *NumSpecConstInfo);
void LLVMDisposeSpecConstInfo(SPIRVSpecSpecConstInfoTy *SpecConstInfos);

LLVMModuleRef LLVMConvertSpirvToLLVM(LLVMContextRef C, SPIRVModuleRef BM,
                                     char **ErrMsg);

LLVMModuleRef LLVMConvertSpirvToLLVMWithOpts(LLVMContextRef C,
                                             SPIRVModuleRef BM,
                                             SPIRVTranslatorOptsRef Opts,
                                             char **ErrMsg);

LLVMBool LLVMRegularizeLlvmForSpirv(LLVMModuleRef M, char **ErrMsg);

LLVMBool LLVMRegularizeLlvmForSpirvWithOpts(LLVMModuleRef M, char **ErrMsg,
                                            SPIRVTranslatorOptsRef Opts);

void LLVMMangleOpenClBuiltin(const char *UnmangledName, LLVMTypeRef *ArgTypes,
                             unsigned NumArgTypes, char **MangledName);

void LLVMInitializeSPIRV(LLVMPassRegistryRef);

void LLVMAddLLVMToSPIRVPass(LLVMPassManagerRef, SPIRVModuleRef);

void LLVMAddOCL20ToSPIRVPass(LLVMPassManagerRef);

void LLVMAddOCL21ToSPIRVPass(LLVMPassManagerRef);

void LLVMAddOCLTypeToSPIRVPass(LLVMPassManagerRef);

void LLVMAddSPIRVLowerBoolPass(LLVMPassManagerRef);

void LLVMAddSPIRVLowerConstExprPass(LLVMPassManagerRef);

void LLVMAddSPIRVLowerSPIRBlocksPass(LLVMPassManagerRef);

void LLVMAddSPIRVLowerOCLBlocksPass(LLVMPassManagerRef);

void LLVMAddSPIRVLowerMemmovePass(LLVMPassManagerRef);

void LLVMAddSPIRVRegularizeLLVMPass(LLVMPassManagerRef);

void LLVMAddSPIRVBIsLoweringPass(LLVMPassManagerRef, LLVMModuleRef,
                                 SPIRVBIsRepresentation);

void LLVMAddSPIRVToOCL12Pass(LLVMPassManagerRef);

void LLVMAddSPIRVToOCL20Pass(LLVMPassManagerRef);

void LLVMAddPreprocessMetadataPass(LLVMPassManagerRef);

LLVM_C_EXTERN_C_END

#endif // SPIRV_C_H
