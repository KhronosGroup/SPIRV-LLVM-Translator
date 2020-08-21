//===- LLVMSPIRVOpts.h - Specify options for translation --------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
// Copyright (c) 2019 Intel Corporation. All rights reserved.
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
/// \file LLVMSPIRVOpts.h
///
/// This files declares helper classes to handle SPIR-V versions.
///
//===----------------------------------------------------------------------===//
#ifndef SPIRV_LLVMSPIRVOPTS_H
#define SPIRV_LLVMSPIRVOPTS_H

#include <cassert>
#include <cstdint>

namespace SPIRV {

enum class VersionNumber : uint32_t {
  // See section 2.3 of SPIR-V spec: Physical Layout of a SPIR_V Module and
  // Instruction
  SPIRV_1_0 = 0x00010000,
  SPIRV_1_1 = 0x00010100,
  SPIRV_1_2 = 0x00010200,
  SPIRV_1_3 = 0x00010300,
  // TODO: populate this enum with the latest versions (up to 1.5) once
  // translator get support of corresponding features
  MinimumVersion = SPIRV_1_0,
  MaximumVersion = SPIRV_1_3
};

enum class BIsRepresentation : uint32_t { OpenCL12, OpenCL20, SPIRVFriendlyIR };

enum class DebugInfoEIS : uint32_t { SPIRV_Debug, OpenCL_DebugInfo_100 };

/// \brief Helper class to manage SPIR-V translation
class TranslatorOpts {
public:
  TranslatorOpts() = default;

  TranslatorOpts(VersionNumber Max) : MaxVersion(Max) {}

  bool isAllowedToUseVersion(VersionNumber RequestedVersion) const {
    return RequestedVersion <= MaxVersion;
  }

  VersionNumber getMaxVersion() const { return MaxVersion; }

  bool isGenArgNameMDEnabled() const { return GenKernelArgNameMD; }

  bool isSPIRVMemToRegEnabled() const { return SPIRVMemToReg; }

  void setMemToRegEnabled(bool Mem2Reg) { SPIRVMemToReg = Mem2Reg; }

  void setGenKernelArgNameMDEnabled(bool ArgNameMD) {
    GenKernelArgNameMD = ArgNameMD;
  }

  void enableGenArgNameMD() { GenKernelArgNameMD = true; }

  void setDesiredBIsRepresentation(BIsRepresentation Value) {
    DesiredRepresentationOfBIs = Value;
  }

  BIsRepresentation getDesiredBIsRepresentation() const {
    return DesiredRepresentationOfBIs;
  }

  bool isSPIRVAllowUnknownIntrinsicsEnabled() const noexcept {
    return SPIRVAllowUnknownIntrinsics;
  }

  void
  setSPIRVAllowUnknownIntrinsicsEnabled(bool AllowUnknownIntrinsics) noexcept {
    SPIRVAllowUnknownIntrinsics = AllowUnknownIntrinsics;
  }

  DebugInfoEIS getDebugInfoEIS() const { return DebugInfoVersion; }

  void setDebugInfoEIS(DebugInfoEIS EIS) { DebugInfoVersion = EIS; }

private:
  // Common translation options
  VersionNumber MaxVersion = VersionNumber::MaximumVersion;
  // SPIRVMemToReg option affects LLVM IR regularization phase
  bool SPIRVMemToReg = false;
  // SPIR-V to LLVM translation options
  bool GenKernelArgNameMD;

  // Representation of built-ins, which should be used while translating from
  // SPIR-V to back to LLVM IR
  BIsRepresentation DesiredRepresentationOfBIs = BIsRepresentation::OpenCL12;

  // Unknown LLVM intrinsics will be translated as external function calls in
  // SPIR-V
  bool SPIRVAllowUnknownIntrinsics = false;

  DebugInfoEIS DebugInfoVersion = DebugInfoEIS::SPIRV_Debug;
};

} // namespace SPIRV

#endif // SPIRV_LLVMSPIRVOPTS_H
