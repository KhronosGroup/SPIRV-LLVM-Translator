//===-- llvm-spirv.cpp - The LLVM/SPIR-V translator utility -----*- C++ -*-===//
//
//
//                     The LLVM/SPIRV Translator
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
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
///  Common Usage:
///  llvm-spirv          - Read LLVM bitcode from stdin, write SPIR-V to stdout
///  llvm-spirv x.bc     - Read LLVM bitcode from the x.bc file, write SPIR-V
///                        to x.bil file
///  llvm-spirv -r       - Read SPIR-V from stdin, write LLVM bitcode to stdout
///  llvm-spirv -r x.bil - Read SPIR-V from the x.bil file, write SPIR-V to
///                        the x.bc file
///
///  Options:
///      --help   - Output command line options
///
//===----------------------------------------------------------------------===//

#include "llvm/Bitcode/BitcodeReader.h"
#include "llvm/Bitcode/BitcodeWriter.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/Error.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/PrettyStackTrace.h"
#include "llvm/Support/Signals.h"
#include "llvm/Support/ToolOutputFile.h"

#ifndef _SPIRV_SUPPORT_TEXT_FMT
#define _SPIRV_SUPPORT_TEXT_FMT
#endif

#include "LLVMSPIRVLib.h"

#include <fstream>
#include <iostream>
#include <memory>

#define DEBUG_TYPE "spirv"

namespace kExt {
const char SpirvBinary[] = ".spv";
const char SpirvText[] = ".spt";
const char LLVMBinary[] = ".bc";
} // namespace kExt

using namespace llvm;

static cl::opt<std::string> InputFile(cl::Positional, cl::desc("<input file>"),
                                      cl::init("-"));

static cl::opt<std::string> OutputFile("o",
                                       cl::desc("Override output filename"),
                                       cl::value_desc("filename"));

static cl::opt<bool>
    IsReverse("r", cl::desc("Reverse translation (SPIR-V to LLVM)"));

static cl::opt<bool>
    IsRegularization("s",
                     cl::desc("Regularize LLVM to be representable by SPIR-V"));

using SPIRV::VersionNumber;

static cl::opt<VersionNumber> MaxSPIRVVersion(
    "spirv-max-version",
    cl::desc("Choose maximum SPIR-V version which can be emitted"),
    cl::values(clEnumValN(VersionNumber::SPIRV_1_0, "1.0", "SPIR-V 1.0"),
               clEnumValN(VersionNumber::SPIRV_1_1, "1.1", "SPIR-V 1.1"),
               clEnumValN(VersionNumber::SPIRV_1_2, "1.2", "SPIR-V 1.2"),
               clEnumValN(VersionNumber::SPIRV_1_3, "1.3", "SPIR-V 1.3")),
    cl::init(VersionNumber::MaximumVersion));
static cl::opt<bool> SPIRVGenKernelArgNameMD(
    "spirv-gen-kernel-arg-name-md", cl::init(false),
    cl::desc("Enable generating OpenCL kernel argument name "
             "metadata"));

static cl::opt<SPIRV::BIsRepresentation> BIsRepresentation(
    "spirv-target-env",
    cl::desc("Specify a representation of different SPIR-V Instructions which "
             "is used when translating from SPIR-V to LLVM IR"),
    cl::values(
        clEnumValN(SPIRV::BIsRepresentation::OpenCL12, "CL1.2", "OpenCL C 1.2"),
        clEnumValN(SPIRV::BIsRepresentation::OpenCL20, "CL2.0", "OpenCL C 2.0"),
        clEnumValN(SPIRV::BIsRepresentation::SPIRVFriendlyIR, "SPV-IR",
                   "SPIR-V Friendly IR")),
    cl::init(SPIRV::BIsRepresentation::OpenCL12));

#ifdef _SPIRV_SUPPORT_TEXT_FMT
namespace SPIRV {
// Use textual format for SPIRV.
extern bool SPIRVUseTextFormat;
} // namespace SPIRV

static cl::opt<bool>
    ToText("to-text",
           cl::desc("Convert input SPIR-V binary to internal textual format"));

static cl::opt<bool> ToBinary(
    "to-binary",
    cl::desc("Convert input SPIR-V in internal textual format to binary"));
#endif

static cl::opt<bool>
    SPIRVMemToReg("spirv-mem2reg", cl::init(false),
                  cl::desc("LLVM/SPIR-V translation enable mem2reg"));

cl::opt<bool> SPIRVAllowUnknownIntrinsics(
    "spirv-allow-unknown-intrinsics", cl::init(false),
    cl::desc("Unknown LLVM intrinsics will be translated as external function "
             "calls in SPIR-V"));

static std::string removeExt(const std::string &FileName) {
  size_t Pos = FileName.find_last_of(".");
  if (Pos != std::string::npos)
    return FileName.substr(0, Pos);
  return FileName;
}

static ExitOnError ExitOnErr;

static int convertLLVMToSPIRV(const SPIRV::TranslatorOpts &Opts) {
  LLVMContext Context;

  std::unique_ptr<MemoryBuffer> MB =
      ExitOnErr(errorOrToExpected(MemoryBuffer::getFileOrSTDIN(InputFile)));
  std::unique_ptr<Module> M =
      ExitOnErr(getOwningLazyBitcodeModule(std::move(MB), Context,
                                           /*ShouldLazyLoadMetadata=*/true));
  ExitOnErr(M->materializeAll());

  if (OutputFile.empty()) {
    if (InputFile == "-")
      OutputFile = "-";
    else
      OutputFile =
          removeExt(InputFile) +
          (SPIRV::SPIRVUseTextFormat ? kExt::SpirvText : kExt::SpirvBinary);
  }

  std::string Err;
  bool Success = false;
  if (OutputFile != "-") {
    std::ofstream OutFile(OutputFile, std::ios::binary);
    Success = writeSpirv(M.get(), Opts, OutFile, Err);
  } else {
    Success = writeSpirv(M.get(), Opts, std::cout, Err);
  }

  if (!Success) {
    errs() << "Fails to save LLVM as SPIR-V: " << Err << '\n';
    return -1;
  }
  return 0;
}

static int convertSPIRVToLLVM(const SPIRV::TranslatorOpts &Opts) {
  LLVMContext Context;
  std::ifstream IFS(InputFile, std::ios::binary);
  Module *M;
  std::string Err;

  if (!readSpirv(Context, Opts, IFS, M, Err)) {
    errs() << "Fails to load SPIR-V as LLVM Module: " << Err << '\n';
    return -1;
  }

  LLVM_DEBUG(dbgs() << "Converted LLVM module:\n" << *M);

  raw_string_ostream ErrorOS(Err);
  if (verifyModule(*M, &ErrorOS)) {
    errs() << "Fails to verify module: " << ErrorOS.str();
    return -1;
  }

  if (OutputFile.empty()) {
    if (InputFile == "-")
      OutputFile = "-";
    else
      OutputFile = removeExt(InputFile) + kExt::LLVMBinary;
  }

  std::error_code EC;
  ToolOutputFile Out(OutputFile.c_str(), EC, sys::fs::F_None);
  if (EC) {
    errs() << "Fails to open output file: " << EC.message();
    return -1;
  }

  WriteBitcodeToFile(*M, Out.os());
  Out.keep();
  delete M;
  return 0;
}

#ifdef _SPIRV_SUPPORT_TEXT_FMT
static int convertSPIRV() {
  if (ToBinary == ToText) {
    errs() << "Invalid arguments\n";
    return -1;
  }
  std::ifstream IFS(InputFile, std::ios::binary);

  if (OutputFile.empty()) {
    if (InputFile == "-")
      OutputFile = "-";
    else {
      OutputFile = removeExt(InputFile) +
                   (ToBinary ? kExt::SpirvBinary : kExt::SpirvText);
    }
  }

  auto Action = [&](std::ostream &OFS) {
    std::string Err;
    if (!SPIRV::convertSpirv(IFS, OFS, Err, ToBinary, ToText)) {
      errs() << "Fails to convert SPIR-V : " << Err << '\n';
      return -1;
    }
    return 0;
  };
  if (OutputFile != "-") {
    std::ofstream OFS(OutputFile);
    return Action(OFS);
  } else
    return Action(std::cout);
}
#endif

static int regularizeLLVM(SPIRV::TranslatorOpts &Opts) {
  LLVMContext Context;

  std::unique_ptr<MemoryBuffer> MB =
      ExitOnErr(errorOrToExpected(MemoryBuffer::getFileOrSTDIN(InputFile)));
  std::unique_ptr<Module> M =
      ExitOnErr(getOwningLazyBitcodeModule(std::move(MB), Context,
                                           /*ShouldLazyLoadMetadata=*/true));
  ExitOnErr(M->materializeAll());

  if (OutputFile.empty()) {
    if (InputFile == "-")
      OutputFile = "-";
    else
      OutputFile = removeExt(InputFile) + ".regularized.bc";
  }

  std::string Err;
  if (!regularizeLlvmForSpirv(M.get(), Err, Opts)) {
    errs() << "Fails to save LLVM as SPIR-V: " << Err << '\n';
    return -1;
  }

  std::error_code EC;
  ToolOutputFile Out(OutputFile.c_str(), EC, sys::fs::F_None);
  if (EC) {
    errs() << "Fails to open output file: " << EC.message();
    return -1;
  }

  WriteBitcodeToFile(*M.get(), Out.os());
  Out.keep();
  return 0;
}

int main(int Ac, char **Av) {
  EnablePrettyStackTrace();
  sys::PrintStackTraceOnErrorSignal(Av[0]);
  PrettyStackTraceProgram X(Ac, Av);

  cl::ParseCommandLineOptions(Ac, Av, "LLVM/SPIR-V translator");

  SPIRV::TranslatorOpts Opts(MaxSPIRVVersion);
  if (BIsRepresentation.getNumOccurrences() != 0) {
    if (!IsReverse) {
      errs() << "Note: --spirv-ocl-builtins-version option ignored as it only "
                "affects translation from SPIR-V to LLVM IR";
    } else {
      Opts.setDesiredBIsRepresentation(BIsRepresentation);
    }
  }

  if (SPIRVMemToReg)
    Opts.setMemToRegEnabled(SPIRVMemToReg);
  if (SPIRVGenKernelArgNameMD)
    Opts.setGenKernelArgNameMDEnabled(SPIRVGenKernelArgNameMD);

  if (SPIRVAllowUnknownIntrinsics.getNumOccurrences() != 0) {
    if (IsReverse) {
      errs()
          << "Note: --spirv-allow-unknown-intrinsics option ignored as it only "
             "affects translation from LLVM IR to SPIR-V";
    } else {
      Opts.setSPIRVAllowUnknownIntrinsicsEnabled(SPIRVAllowUnknownIntrinsics);
    }
  }

#ifdef _SPIRV_SUPPORT_TEXT_FMT
  if (ToText && (ToBinary || IsReverse || IsRegularization)) {
    errs() << "Cannot use -to-text with -to-binary, -r, -s\n";
    return -1;
  }

  if (ToBinary && (ToText || IsReverse || IsRegularization)) {
    errs() << "Cannot use -to-binary with -to-text, -r, -s\n";
    return -1;
  }

  if (ToBinary || ToText)
    return convertSPIRV();
#endif

  if (!IsReverse && !IsRegularization)
    return convertLLVMToSPIRV(Opts);

  if (IsReverse && IsRegularization) {
    errs() << "Cannot have both -r and -s options\n";
    return -1;
  }
  if (IsReverse)
    return convertSPIRVToLLVM(Opts);

  if (IsRegularization)
    return regularizeLLVM(Opts);

  return 0;
}
