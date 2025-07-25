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
/// This files declares helper classes to handle SPIR-V versions and extensions.
///
//===----------------------------------------------------------------------===//
#ifndef SPIRV_LLVMSPIRVOPTS_H
#define SPIRV_LLVMSPIRVOPTS_H

#include <llvm/ADT/SmallVector.h>
#include <llvm/ADT/StringRef.h>

#include <cassert>
#include <cstdint>
#include <map>
#include <optional>
#include <unordered_map>

namespace llvm {
class IntrinsicInst;
} // namespace llvm

namespace SPIRV {

/// SPIR-V versions known to translator.
enum class VersionNumber : uint32_t {
  // See section 2.3 of SPIR-V spec: Physical Layout of a SPIR_V Module and
  // Instruction
  SPIRV_1_0 = 0x00010000,
  SPIRV_1_1 = 0x00010100,
  SPIRV_1_2 = 0x00010200,
  SPIRV_1_3 = 0x00010300,
  SPIRV_1_4 = 0x00010400,
  SPIRV_1_5 = 0x00010500,
  SPIRV_1_6 = 0x00010600,
  MinimumVersion = SPIRV_1_0,
  MaximumVersion = SPIRV_1_6
};

inline constexpr std::string_view formatVersionNumber(uint32_t Version) {
  switch (Version) {
  case static_cast<uint32_t>(VersionNumber::SPIRV_1_0):
    return "1.0";
  case static_cast<uint32_t>(VersionNumber::SPIRV_1_1):
    return "1.1";
  case static_cast<uint32_t>(VersionNumber::SPIRV_1_2):
    return "1.2";
  case static_cast<uint32_t>(VersionNumber::SPIRV_1_3):
    return "1.3";
  case static_cast<uint32_t>(VersionNumber::SPIRV_1_4):
    return "1.4";
  case static_cast<uint32_t>(VersionNumber::SPIRV_1_5):
    return "1.5";
  case static_cast<uint32_t>(VersionNumber::SPIRV_1_6):
    return "1.6";
  }
  return "unknown";
}

inline bool isSPIRVVersionKnown(VersionNumber Ver) {
  return Ver >= VersionNumber::MinimumVersion &&
         Ver <= VersionNumber::MaximumVersion;
}

enum class ExtensionID : uint32_t {
  First,
#define EXT(X) X,
#include "LLVMSPIRVExtensions.inc"
#undef EXT
  Last,
};

enum class ExtInst : uint32_t { None, OpenCL };

enum class BIsRepresentation : uint32_t { OpenCL12, OpenCL20, SPIRVFriendlyIR };

enum class FPContractMode : uint32_t { On, Off, Fast };

enum class DebugInfoEIS : uint32_t {
  SPIRV_Debug,
  OpenCL_DebugInfo_100,
  NonSemantic_Shader_DebugInfo_100,
  NonSemantic_Shader_DebugInfo_200
};

enum class BuiltinFormat : uint32_t { Function, Global };

/// \brief Helper class to manage SPIR-V translation
class TranslatorOpts {
public:
  // Unset optional means not directly specified by user
  using ExtensionsStatusMap = std::map<ExtensionID, std::optional<bool>>;

  using ArgList = llvm::SmallVector<llvm::StringRef, 4>;

  TranslatorOpts() = default;

  TranslatorOpts(VersionNumber Max, const ExtensionsStatusMap &Map = {})
      : MaxVersion(Max), ExtStatusMap(Map) {}

  bool isAllowedToUseVersion(VersionNumber RequestedVersion) const {
    return RequestedVersion <= MaxVersion;
  }

  bool isAllowedToUseExtension(ExtensionID Extension) const {
    auto I = ExtStatusMap.find(Extension);
    if (ExtStatusMap.end() == I)
      return false;

    return I->second && *I->second;
  }

  void setAllowedToUseExtension(ExtensionID Extension, bool Allow = true) {
    // Only allow using the extension if it has not already been disabled
    auto I = ExtStatusMap.find(Extension);
    if (I == ExtStatusMap.end() || !I->second || (*I->second) == true)
      ExtStatusMap[Extension] = Allow;
  }

  std::vector<std::string>
  getAllowedSPIRVExtensionNames(std::function<bool(ExtensionID)> &Filter) const;

  VersionNumber getMaxVersion() const { return MaxVersion; }

  bool isGenArgNameMDEnabled() const { return GenKernelArgNameMD; }

  bool isSPIRVMemToRegEnabled() const { return SPIRVMemToReg; }

  void setMemToRegEnabled(bool Mem2Reg) { SPIRVMemToReg = Mem2Reg; }

  bool preserveAuxData() const { return PreserveAuxData; }

  void setPreserveAuxData(bool ArgValue) { PreserveAuxData = ArgValue; }

  void setGenKernelArgNameMDEnabled(bool ArgNameMD) {
    GenKernelArgNameMD = ArgNameMD;
  }

  void enableAllExtensions();

  void enableGenArgNameMD() { GenKernelArgNameMD = true; }

  void setSpecConst(uint32_t SpecId, uint64_t SpecValue) {
    ExternalSpecialization[SpecId] = SpecValue;
  }

  bool getSpecializationConstant(uint32_t SpecId, uint64_t &Value) const {
    auto It = ExternalSpecialization.find(SpecId);
    if (It == ExternalSpecialization.end())
      return false;
    Value = It->second;
    return true;
  }

  void setExtInst(ExtInst Value) {
    // --spirv-ext-inst supersedes --spirv-replace-fmuladd-with-ocl-mad
    ReplaceLLVMFmulAddWithOpenCLMad = false;
    ExtInstValue = Value;
  }

  ExtInst getExtInst() const { return ExtInstValue; }

  void setDesiredBIsRepresentation(BIsRepresentation Value) {
    DesiredRepresentationOfBIs = Value;
  }

  BIsRepresentation getDesiredBIsRepresentation() const {
    return DesiredRepresentationOfBIs;
  }

  void setFPContractMode(FPContractMode Mode) { FPCMode = Mode; }

  FPContractMode getFPContractMode() const { return FPCMode; }

  bool isUnknownIntrinsicAllowed(llvm::IntrinsicInst *II) const noexcept;
  bool isSPIRVAllowUnknownIntrinsicsEnabled() const noexcept;
  void setSPIRVAllowUnknownIntrinsics(ArgList IntrinsicPrefixList) noexcept;

  bool allowExtraDIExpressions() const noexcept {
    return AllowExtraDIExpressions;
  }

  void setAllowExtraDIExpressionsEnabled(bool Allow) noexcept {
    AllowExtraDIExpressions = Allow;
  }

  DebugInfoEIS getDebugInfoEIS() const { return DebugInfoVersion; }

  void setDebugInfoEIS(DebugInfoEIS EIS) { DebugInfoVersion = EIS; }

  bool shouldReplaceLLVMFmulAddWithOpenCLMad() const noexcept {
    return ReplaceLLVMFmulAddWithOpenCLMad;
  }

  void setReplaceLLVMFmulAddWithOpenCLMad(bool Value) noexcept {
    ReplaceLLVMFmulAddWithOpenCLMad = Value;
  }

  bool shouldPreserveOCLKernelArgTypeMetadataThroughString() const noexcept {
    return PreserveOCLKernelArgTypeMetadataThroughString;
  }

  void setPreserveOCLKernelArgTypeMetadataThroughString(bool Value) noexcept {
    PreserveOCLKernelArgTypeMetadataThroughString = Value;
  }

  bool shouldEmitFunctionPtrAddrSpace() const noexcept {
    return EmitFunctionPtrAddrSpace;
  }

  void setEmitFunctionPtrAddrSpace(bool Value) noexcept {
    EmitFunctionPtrAddrSpace = Value;
  }

  void setBuiltinFormat(BuiltinFormat Value) noexcept {
    SPIRVBuiltinFormat = Value;
  }
  BuiltinFormat getBuiltinFormat() const noexcept { return SPIRVBuiltinFormat; }

  void setUseLLVMTarget(bool Flag) noexcept { UseLLVMTarget = Flag; }
  bool getUseLLVMTarget() const noexcept { return UseLLVMTarget; }

  void setFnVarCategory(uint32_t Category) noexcept {
    FnVarCategory = Category;
  }
  std::optional<uint32_t> getFnVarCategory() const noexcept {
    return FnVarCategory;
  }

  void setFnVarFamily(uint32_t Family) noexcept { FnVarFamily = Family; }
  std::optional<uint32_t> getFnVarFamily() const noexcept {
    return FnVarFamily;
  }

  void setFnVarArch(uint32_t Arch) noexcept { FnVarArch = Arch; }
  std::optional<uint32_t> getFnVarArch() const noexcept { return FnVarArch; }

  void setFnVarTarget(uint32_t Target) noexcept { FnVarTarget = Target; }
  std::optional<uint32_t> getFnVarTarget() const noexcept {
    return FnVarTarget;
  }

  void setFnVarFeatures(std::vector<uint32_t> Features) noexcept {
    FnVarFeatures = Features;
  }
  std::vector<uint32_t> getFnVarFeatures() const noexcept {
    return FnVarFeatures;
  }

  void setFnVarCapabilities(std::vector<uint32_t> Capabilities) noexcept {
    FnVarCapabilities = Capabilities;
  }
  std::vector<uint32_t> getFnVarCapabilities() const noexcept {
    return FnVarCapabilities;
  }

  void setFnVarSpecEnable(bool Val) noexcept { FnVarSpecEnable = Val; }
  bool getFnVarSpecEnable() const noexcept { return FnVarSpecEnable; }

  void setFnVarSpvOut(std::string Val) noexcept { FnVarSpvOut = Val; }
  std::string getFnVarSpvOut() const noexcept { return FnVarSpvOut; }

  // Check that options passed to --fnvar-xxx flags make sense. Return true on
  // success, false on failure.
  bool validateFnVarOpts() const;

private:
  // Common translation options
  VersionNumber MaxVersion = VersionNumber::MaximumVersion;
  ExtensionsStatusMap ExtStatusMap;
  // SPIRVMemToReg option affects LLVM IR regularization phase
  bool SPIRVMemToReg = false;
  // SPIR-V to LLVM translation options
  bool GenKernelArgNameMD = false;
  std::unordered_map<uint32_t, uint64_t> ExternalSpecialization;
  // Extended instruction set to use when translating from LLVM IR to SPIR-V
  ExtInst ExtInstValue = ExtInst::None;
  // Representation of built-ins, which should be used while translating from
  // SPIR-V to back to LLVM IR
  BIsRepresentation DesiredRepresentationOfBIs = BIsRepresentation::OpenCL12;
  // Controls floating point contraction.
  //
  // - FPContractMode::On allows to choose a mode according to
  //   presence of fused LLVM intrinsics
  //
  // - FPContractMode::Off disables contratction for all entry points
  //
  // - FPContractMode::Fast allows *all* operations to be contracted
  //   for all entry points
  FPContractMode FPCMode = FPContractMode::On;

  // Unknown LLVM intrinsics will be translated as external function calls in
  // SPIR-V
  std::optional<ArgList> SPIRVAllowUnknownIntrinsics{};

  // Enable support for extra DIExpression opcodes not listed in the SPIR-V
  // DebugInfo specification.
  bool AllowExtraDIExpressions = false;

  DebugInfoEIS DebugInfoVersion = DebugInfoEIS::OpenCL_DebugInfo_100;

  // Controls whether llvm.fmuladd.* should be replaced with mad from OpenCL
  // extended instruction set or with a simple fmul + fadd
  bool ReplaceLLVMFmulAddWithOpenCLMad = true;

  // Add a workaround to preserve OpenCL kernel_arg_type and
  // kernel_arg_type_qual metadata through OpString
  bool PreserveOCLKernelArgTypeMetadataThroughString = false;

  // Controls if CodeSectionINTEL can be emitted and consumed with a dedicated
  // address space
  bool EmitFunctionPtrAddrSpace = false;

  bool PreserveAuxData = false;

  std::optional<uint32_t> FnVarCategory = std::nullopt;
  std::optional<uint32_t> FnVarFamily = std::nullopt;
  std::optional<uint32_t> FnVarArch = std::nullopt;
  std::optional<uint32_t> FnVarTarget = std::nullopt;
  std::vector<uint32_t> FnVarFeatures = {};
  std::vector<uint32_t> FnVarCapabilities = {};
  std::string FnVarSpvOut = "";
  bool FnVarSpecEnable = false;

  BuiltinFormat SPIRVBuiltinFormat = BuiltinFormat::Function;

  // Convert LLVM to SPIR-V using the LLVM SPIR-V Backend target
  bool UseLLVMTarget = false;
};

} // namespace SPIRV

#endif // SPIRV_LLVMSPIRVOPTS_H
