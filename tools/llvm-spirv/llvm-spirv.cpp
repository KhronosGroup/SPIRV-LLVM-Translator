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
///  llvm-spirv          - Read LLVM bitcode from stdin, write SPIRV to stdout
///  llvm-spirv x.bc     - Read LLVM bitcode from the x.bc file, write SPIR-V
///                        to x.bil file
///  llvm-spirv -r       - Read SPIRV from stdin, write LLVM bitcode to stdout
///  llvm-spirv -r x.bil - Read SPIRV from the x.bil file, write SPIR-V to
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
#include "llvm/Support/raw_ostream.h"

#include "../../lib/SPIRV/libSPIRV/spirv.hpp"

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
const char SpirvText[]   = ".spt";
const char LLVMBinary[]  = ".bc";
const char GlslVert[]    = ".vert";
const char GlslTesc[]    = ".tesc";
const char GlslTese[]    = ".tese";
const char GlslGeom[]    = ".geom";
const char GlslFrag[]    = ".frag";
const char GlslComp[]    = ".comp";
const char OCLKern[]     = ".kern";
} // namespace kExt

std::map<std::string, spv::ExecutionModel> inputModelMap =
{
    { kExt::GlslVert, spv::ExecutionModelVertex },
    { kExt::GlslTesc, spv::ExecutionModelTessellationControl },
    { kExt::GlslTese, spv::ExecutionModelTessellationEvaluation },
    { kExt::GlslGeom, spv::ExecutionModelGeometry },
    { kExt::GlslFrag, spv::ExecutionModelFragment },
    { kExt::GlslComp, spv::ExecutionModelGLCompute },
    { kExt::OCLKern,  spv::ExecutionModelKernel }, // Default
};

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

static std::string removeExt(const std::string &FileName) {
  size_t Pos = FileName.find_last_of(".");
  if (Pos != std::string::npos)
    return FileName.substr(0, Pos);
  return FileName;
}

static ExitOnError ExitOnErr;

static int convertLLVMToSPIRV() {
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

  llvm::StringRef OutFile(OutputFile);
  std::error_code EC;
  std::string Err;
  llvm::raw_fd_ostream OFS(OutFile, EC, llvm::sys::fs::F_None);
  if (!writeSpirv(M.get(), OFS, Err)) {
    errs() << "Fails to save LLVM as SPIRV: " << Err << '\n';
    return -1;
  }
  return 0;
}

spv::ExecutionModel getExecModelFilename( const std::string& InputFile )
{
    size_t extPos = InputFile.find_last_of(".");
    if( extPos == std::string::npos )
    {
        return spv::ExecutionModelKernel;
    }

    size_t modelPos = InputFile.substr(0, extPos).find_last_of(".");

    if( modelPos == std::string::npos )
    {
        return spv::ExecutionModelKernel;
    }

    std::string modelExt = InputFile.substr( modelPos, InputFile.size() - extPos + 1 );

    if( modelExt.empty() )
    {
        return spv::ExecutionModelKernel;
    }

    auto modelType = inputModelMap.find( modelExt );

    if( modelType == inputModelMap.end() )
    {
        return spv::ExecutionModelKernel;
    }

    return modelType->second;
}

static int convertSPIRVToLLVM() {
  LLVMContext Context;
  std::ifstream IFS(InputFile, std::ios::binary);
  Module *M;
  std::string Err;

  // TODO: Multiple input files?
{
  spv::ExecutionModel execModel = getExecModelFilename(InputFile);

  // TODO: Entry point name as argument
  std::string entryPoint = "main";

  if (!readSpirv(Context, IFS, M, Err, execModel, entryPoint)) {
    errs() << "Fails to load SPIRV as LLVM Module: " << Err << '\n';
    return -1;
  }

  LLVM_DEBUG(dbgs() << "Converted LLVM module:\n" << *M);
}

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

  auto Action = [&](llvm::raw_ostream &OFS) {
    std::string Err;
    if (!SPIRV::convertSpirv(IFS, OFS, Err, ToBinary, ToText)) {
      errs() << "Fails to convert SPIR-V : " << Err << '\n';
      return -1;
    }
    return 0;
  };
  if (OutputFile != "-") {
    std::error_code EC;
    llvm::raw_fd_ostream OFS(llvm::StringRef(OutputFile), EC,
                             llvm::sys::fs::F_None);
    return Action(OFS);
  } else
    return Action(outs());
}
#endif

static int regularizeLLVM() {
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
  if (!regularizeLlvmForSpirv(M.get(), Err)) {
    errs() << "Fails to save LLVM as SPIRV: " << Err << '\n';
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
    return convertLLVMToSPIRV();

  if (IsReverse && IsRegularization) {
    errs() << "Cannot have both -r and -s options\n";
    return -1;
  }
  if (IsReverse)
    return convertSPIRVToLLVM();

  if (IsRegularization)
    return regularizeLLVM();

  return 0;
}
