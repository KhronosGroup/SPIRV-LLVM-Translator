//===- SPIRVLibC.h - Read and write SPIR-V binary -----------------*- C -*-===//
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
/// \file SPIRVLibC.h
///
/// This files implements the C API for translating between LLVM and SPIR-V.
///
//===----------------------------------------------------------------------===//

#include "LLVMSPIRVLib.h"
#include "LLVMSPIRVLibC.h"

#include "llvm/IR/LegacyPassManager.h"
#include "llvm/IR/Module.h"

#include "SPIRVModule.h"

#include <sstream>

using namespace SPIRV;
using namespace llvm;

LLVMBool SPIRVIsSpirvBinary(const char *ImgBuf, unsigned ImgLen) {
  std::string ImgStr = std::string(ImgBuf, ImgLen);
  return isSpirvBinary(ImgStr);
}

#ifdef _SPIRV_C_SUPPORT_TEXT_FMT

LLVMBool SPIRVIsSpirvText(const char *ImgBuf, unsigned ImgLen) {
  std::string ImgStr = std::string(ImgBuf, ImgLen);
  return isSpirvText(ImgStr);
}

LLVMBool SPIRVConvertSpirv(const char *InputBuf, unsigned InputLen, char **Out,
                           char **ErrMsg, LLVMBool ToText) {
  std::string InputStr = std::string(InputBuf, InputLen);
  std::string OutStr, ErrMsgStr;
  if (convertSpirv(InputStr, OutStr, ErrMsgStr, ToText)) {
    *Out = LLVMCreateMessage(OutStr.c_str());
    return true;
  } else {
    *ErrMsg = LLVMCreateMessage(ErrMsgStr.c_str());
    return false;
  }
}

#endif

SPIRVModuleRef SPIRVReadSpirvModule(const char *ImgBuf, unsigned ImgLen,
                                    char **ErrMsg) {
  std::string ImgStr = std::string(ImgBuf, ImgLen);
  std::istringstream IS(ImgStr);
  std::string ErrMsgStr;
  std::unique_ptr<SPIRVModule> Mod = readSpirvModule(IS, ErrMsgStr);
  if (Mod) {
    return wrap(Mod.get());
  } else {
    *ErrMsg = LLVMCreateMessage(ErrMsgStr.c_str());
    return NULL;
  }
}

SPIRVModuleRef SPIRVReadSpirvModuleWithOpts(const char *ImgBuf, unsigned ImgLen,
                                            SPIRVTranslatorOptsRef Opts,
                                            char **ErrMsg) {
  std::string ImgStr = std::string(ImgBuf, ImgLen);
  std::istringstream IS(ImgStr);
  std::string ErrMsgStr;
  std::unique_ptr<SPIRVModule> Mod =
      readSpirvModule(IS, *unwrap(Opts), ErrMsgStr);
  if (Mod) {
    return wrap(Mod.get());
  } else {
    *ErrMsg = LLVMCreateMessage(ErrMsgStr.c_str());
    return NULL;
  }
}

LLVMBool LLVMWriteSpirv(LLVMModuleRef M, LLVMMemoryBufferRef *Out,
                        char **ErrMsg) {
  std::ostringstream OS;
  std::string ErrMsgStr;
  if (writeSpirv(unwrap(M), OS, ErrMsgStr)) {
    *Out = wrap(MemoryBuffer::getMemBufferCopy(OS.str()).release());
    return true;
  } else {
    *ErrMsg = LLVMCreateMessage(ErrMsgStr.c_str());
    return false;
  }
}

LLVMBool LLVMReadSpirv(LLVMContextRef C, const char *ImgBuf, unsigned ImgLen,
                       LLVMModuleRef *M, char **ErrMsg) {
  std::string ImgStr = std::string(ImgBuf, ImgLen);
  std::istringstream IS(ImgStr);
  Module *Mod;
  std::string ErrMsgStr;
  if (readSpirv(*unwrap(C), IS, Mod, ErrMsgStr)) {
    *M = wrap(Mod);
    return true;
  } else {
    *ErrMsg = LLVMCreateMessage(ErrMsgStr.c_str());
    return false;
  }
}

LLVMBool LLVMWriteSpirvWithOpts(LLVMModuleRef M, SPIRVTranslatorOptsRef Opts,
                                LLVMMemoryBufferRef *Out, char **ErrMsg) {
  std::ostringstream OS;
  std::string ErrMsgStr;
  if (writeSpirv(unwrap(M), *unwrap(Opts), OS, ErrMsgStr)) {
    *Out = wrap(MemoryBuffer::getMemBufferCopy(OS.str()).release());
    return true;
  } else {
    *ErrMsg = LLVMCreateMessage(ErrMsgStr.c_str());
    return false;
  }
}

LLVMBool LLVMReadSpirvWithOpts(LLVMContextRef C, SPIRVTranslatorOptsRef Opts,
                               const char *ImgBuf, unsigned ImgLen,
                               LLVMModuleRef *M, char **ErrMsg) {
  std::string ImgStr = std::string(ImgBuf, ImgLen);
  std::istringstream IS(ImgStr);
  Module *Mod;
  std::string ErrMsgStr;
  if (readSpirv(*unwrap(C), *unwrap(Opts), IS, Mod, ErrMsgStr)) {
    *M = wrap(Mod);
    return true;
  } else {
    *ErrMsg = LLVMCreateMessage(ErrMsgStr.c_str());
    return false;
  }
}

LLVMBool LLVMGetSpecConstInfo(const char *ImgBuf, unsigned ImgLen,
                              SPIRVSpecSpecConstInfoTy **SpecConstInfos,
                              unsigned *NumSpecConstInfos) {
  std::string ImgStr = std::string(ImgBuf, ImgLen);
  std::istringstream IS(ImgStr);
  std::vector<SpecConstInfoTy> SpecConstInfoVec;
  if (getSpecConstInfo(IS, SpecConstInfoVec)) {
    *NumSpecConstInfos = SpecConstInfoVec.size();
    *SpecConstInfos = (SPIRVSpecSpecConstInfoTy *)malloc(
        sizeof(SPIRVSpecSpecConstInfoTy) * SpecConstInfoVec.size());
    for (int i = 0; i < SpecConstInfoVec.size(); i++) {
      (*SpecConstInfos)[i].first = SpecConstInfoVec[i].first;
      (*SpecConstInfos)[i].second = SpecConstInfoVec[i].second;
    }
    return true;
  } else {
    return false;
  }
}

void LLVMDisposeSpecConstInfo(SPIRVSpecSpecConstInfoTy *SpecConstInfos) {
  free(SpecConstInfos);
}

LLVMModuleRef LLVMConvertSpirvToLLVM(LLVMContextRef C, SPIRVModuleRef BM,
                                     char **ErrMsg) {
  std::string ErrMsgStr;
  std::unique_ptr<Module> Mod =
      convertSpirvToLLVM(*unwrap(C), *unwrap(BM), ErrMsgStr);
  if (Mod) {
    return wrap(Mod.get());
  } else {
    *ErrMsg = LLVMCreateMessage(ErrMsgStr.c_str());
    return NULL;
  }
}

LLVMModuleRef LLVMConvertSpirvToLLVMWithOpts(LLVMContextRef C,
                                             SPIRVModuleRef BM,
                                             SPIRVTranslatorOptsRef Opts,
                                             char **ErrMsg) {
  std::string ErrMsgStr;
  std::unique_ptr<Module> Mod =
      convertSpirvToLLVM(*unwrap(C), *unwrap(BM), *unwrap(Opts), ErrMsgStr);
  if (Mod) {
    return wrap(Mod.get());
  } else {
    *ErrMsg = LLVMCreateMessage(ErrMsgStr.c_str());
    return NULL;
  }
}

LLVMBool LLVMRegularizeLlvmForSpirv(LLVMModuleRef M, char **ErrMsg) {
  std::string ErrMsgStr;
  if (regularizeLlvmForSpirv(unwrap(M), ErrMsgStr)) {
    return true;
  } else {
    *ErrMsg = LLVMCreateMessage(ErrMsgStr.c_str());
    return false;
  }
}

LLVMBool LLVMRegularizeLlvmForSpirvWithOpts(LLVMModuleRef M, char **ErrMsg,
                                            SPIRVTranslatorOptsRef Opts) {
  std::string ErrMsgStr;
  if (regularizeLlvmForSpirv(unwrap(M), ErrMsgStr, *unwrap(Opts))) {
    return true;
  } else {
    *ErrMsg = LLVMCreateMessage(ErrMsgStr.c_str());
    return false;
  }
}

void LLVMMangleOpenClBuiltin(const char *UnmangledName, LLVMTypeRef *ArgTypes,
                             unsigned NumArgTypes, char **MangledName) {
  ArrayRef<Type *> ArgTypesArr = makeArrayRef(unwrap(ArgTypes), NumArgTypes);
  std::string UnmangledNameStr(UnmangledName), MangledNameStr;
  mangleOpenClBuiltin(UnmangledName, ArgTypesArr, MangledNameStr);
  *MangledName = LLVMCreateMessage(MangledNameStr.c_str());
  return;
}

void LLVMInitializeSPIRV(LLVMPassRegistryRef R) {
  initializeLLVMToSPIRVPass(*unwrap(R));
  initializeOCL20ToSPIRVPass(*unwrap(R));
  initializeOCL21ToSPIRVPass(*unwrap(R));
  initializeOCLTypeToSPIRVPass(*unwrap(R));
  initializeSPIRVLowerBoolPass(*unwrap(R));
  initializeSPIRVLowerConstExprPass(*unwrap(R));
  initializeSPIRVLowerSPIRBlocksPass(*unwrap(R));
  initializeSPIRVLowerOCLBlocksPass(*unwrap(R));
  initializeSPIRVLowerMemmovePass(*unwrap(R));
  initializeSPIRVRegularizeLLVMPass(*unwrap(R));
  initializeSPIRVToOCL12Pass(*unwrap(R));
  initializeSPIRVToOCL20Pass(*unwrap(R));
  initializePreprocessMetadataPass(*unwrap(R));
}

void LLVMAddLLVMToSPIRVPass(LLVMPassManagerRef PM, SPIRVModuleRef SMod) {
  unwrap(PM)->add(createLLVMToSPIRV(unwrap(SMod)));
}

void LLVMAddOCL20ToSPIRVPass(LLVMPassManagerRef PM) {
  unwrap(PM)->add(createOCL20ToSPIRV());
}

void LLVMAddOCL21ToSPIRVPass(LLVMPassManagerRef PM) {
  unwrap(PM)->add(createOCL21ToSPIRV());
}

void LLVMAddOCLTypeToSPIRVPass(LLVMPassManagerRef PM) {
  unwrap(PM)->add(createOCLTypeToSPIRV());
}

void LLVMAddSPIRVLowerBoolPass(LLVMPassManagerRef PM) {
  unwrap(PM)->add(createSPIRVLowerBool());
}

void LLVMAddSPIRVLowerConstExprPass(LLVMPassManagerRef PM) {
  unwrap(PM)->add(createSPIRVLowerConstExpr());
}

void LLVMAddSPIRVLowerSPIRBlocksPass(LLVMPassManagerRef PM) {
  unwrap(PM)->add(createSPIRVLowerSPIRBlocks());
}

void LLVMAddSPIRVLowerOCLBlocksPass(LLVMPassManagerRef PM) {
  unwrap(PM)->add(createSPIRVLowerOCLBlocks());
}

void LLVMAddSPIRVLowerMemmovePass(LLVMPassManagerRef PM) {
  unwrap(PM)->add(createSPIRVLowerMemmove());
}

void LLVMAddSPIRVRegularizeLLVMPass(LLVMPassManagerRef PM) {
  unwrap(PM)->add(createSPIRVRegularizeLLVM());
}

void LLVMAddSPIRVBIsLoweringPass(LLVMPassManagerRef PM, LLVMModuleRef M,
                                 SPIRVBIsRepresentation BIsRepresentation) {
  unwrap(PM)->add(
      createSPIRVBIsLoweringPass(*unwrap(M), unwrap(BIsRepresentation)));
}

void LLVMAddSPIRVToOCL12Pass(LLVMPassManagerRef PM) {
  unwrap(PM)->add(createSPIRVToOCL12());
}

void LLVMAddSPIRVToOCL20Pass(LLVMPassManagerRef PM) {
  unwrap(PM)->add(createSPIRVToOCL20());
}

void LLVMAddPreprocessMetadataPass(LLVMPassManagerRef PM) {
  unwrap(PM)->add(createPreprocessMetadata());
}
