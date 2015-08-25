//===-- llvm-spirv.cpp - The LLVM/SPIR-V translator utility -----*- C++ -*-===//
//
//
//                     The LLVM/SPRV Translator
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

#include "llvm/Bitcode/ReaderWriter.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/DataStream.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/ToolOutputFile.h"
#include "SPIRV.h"

#include <memory>
#include <fstream>
#include <iostream>

#define DEBUG_TYPE "spirv"

namespace kExt {
  const char SpirvBinary[] = ".spv";
  const char SpirvText[] = ".spt";
  const char LLVMBinary[] = ".bc";
};

using namespace llvm;

static cl::opt<std::string>
InputFile(cl::Positional, cl::desc("<input file>"), cl::init("-"));

static cl::opt<std::string>
OutputFile("o", cl::desc("Override output filename"),
               cl::value_desc("filename"));

static cl::opt<bool>
IsReverse("r", cl::desc("Reverse translation (SPIR-V to LLVM)"));

static cl::opt<bool>
IsRegularization("s", cl::desc(
    "Regularize LLVM to be representable by SPIR-V"));

static cl::opt<bool>
ToText("to-text", cl::desc("Convert input SPIR-V binary to internal textual format"));

static cl::opt<bool>
ToBinary("to-binary",
    cl::desc("Convert input SPIR-V in internal textual format to binary"));

static std::string
removeExt(const std::string& FileName) {
  size_t Pos = FileName.find_last_of(".");
  if (Pos != std::string::npos)
    return FileName.substr(0, Pos);
  return FileName;
}

static int
convertLLVMToSPRV() {
  LLVMContext Context;

  std::string Err;
  DataStreamer *DS = getDataFileStreamer(InputFile, &Err);
  if (!DS) {
    errs() << "Fails to open input file: " << Err;
    return -1;
  }

  ErrorOr<std::unique_ptr<Module>> MOrErr =
      getStreamedBitcodeModule(InputFile, DS, Context);

  if (std::error_code EC = MOrErr.getError()) {
    errs() << "Fails to load bitcode: " << EC.message();
    return -1;
  }
  
  std::unique_ptr<Module> M = std::move(*MOrErr);

  if (std::error_code EC = M->materializeAllPermanently()){
    errs() << "Fails to materialize: " << EC.message();
    return -1;
  }

  if (OutputFile.empty()) {
    if (InputFile == "-")
      OutputFile = "-";
    else
      OutputFile = removeExt(InputFile) + kExt::SpirvBinary;
  }

  std::ofstream OFS(OutputFile, std::ios::binary);
  if (!WriteSPRV(M.get(), OFS, Err)) {
    errs() << "Fails to save LLVM as SPRV: " << Err << '\n';
    return -1;
  }
  return 0;
}

static int
convertSPRVToLLVM() {
  LLVMContext Context;
  std::ifstream IFS(InputFile, std::ios::binary);
  Module *M;
  std::string Err;

  if (!ReadSPRV(Context, IFS, M, Err)) {
    errs() << "Fails to load SPIRV as LLVM Module: " << Err << '\n';
    return -1;
  }

  DEBUG(dbgs() << "Converted LLVM module:\n" << *M);


  raw_string_ostream ErrorOS(Err);
  if (verifyModule(*M, &ErrorOS)){
    errs() << "Fails to verify module: " << Err;
    return -1;
  }

  if (OutputFile.empty()) {
    if (InputFile == "-")
      OutputFile = "-";
    else
      OutputFile = removeExt(InputFile) + kExt::LLVMBinary;
  }

  std::error_code EC;
  tool_output_file Out(OutputFile.c_str(), EC, sys::fs::F_None);
  if (EC) {
    errs() << "Fails to open output file: " << EC.message();
    return -1;
  }

  WriteBitcodeToFile(M, Out.os());
  Out.keep();
  delete M;
  return 0;
}

static int
convertSPRV() {
  if (ToBinary == ToText) {
    errs() << "Invalid arguments\n";
    return -1;
  }
  std::ifstream IFS(InputFile, std::ios::binary);

  if (OutputFile.empty()) {
    if (InputFile == "-")
      OutputFile = "-";
    else {
      OutputFile = removeExt(InputFile)
                 + (ToBinary?kExt::SpirvBinary:kExt::SpirvText);
    }
  }

  auto Action = [&](std::ostream &OFS) {
    std::string Err;
      if (!SPRV::ConvertSPRV(IFS, OFS, Err, ToBinary, ToText)) {
      errs() << "Fails to convert SPIR-V : " << Err << '\n';
      return -1;
    }
    return 0;
  };
  if (OutputFile != "-") {
    std::ofstream OFS(OutputFile, std::ios::binary);
    return Action(OFS);
  } else
    return Action(std::cout);
}

static int
regularizeLLVM() {
  LLVMContext Context;

  std::string Err;
  DataStreamer *DS = getDataFileStreamer(InputFile, &Err);
  if (!DS) {
    errs() << "Fails to open input file: " << Err;
    return -1;
  }

  ErrorOr<std::unique_ptr<Module>> MOrErr =
      getStreamedBitcodeModule(InputFile, DS, Context);

  if (std::error_code EC = MOrErr.getError()) {
    errs() << "Fails to load bitcode: " << EC.message();
    return -1;
  }
  
  std::unique_ptr<Module> M = std::move(*MOrErr);

  if (std::error_code EC = M->materializeAllPermanently()){
    errs() << "Fails to materialize: " << EC.message();
    return -1;
  }

  if (OutputFile.empty()) {
    if (InputFile == "-")
      OutputFile = "-";
    else
      OutputFile = removeExt(InputFile) + ".regularized.bc";
  }

  if (!RegularizeLLVMForSPRV(M.get(), Err)) {
    errs() << "Fails to save LLVM as SPRV: " << Err << '\n';
    return -1;
  }

  std::error_code EC;
  tool_output_file Out(OutputFile.c_str(), EC, sys::fs::F_None);
  if (EC) {
    errs() << "Fails to open output file: " << EC.message();
    return -1;
  }

  WriteBitcodeToFile(M.get(), Out.os());
  Out.keep();
  return 0;
}


int
main(int ac, char** av) {
  cl::ParseCommandLineOptions(ac, av, "LLVM/SPIR-V translator");

  if (ToText && (ToBinary || IsReverse || IsRegularization)) {
    errs() << "Cannot use -to-text with -to-binary, -r, -s\n";
    return -1;
  }

  if (ToBinary && (ToText || IsReverse || IsRegularization)) {
    errs() << "Cannot use -to-binary with -to-text, -r, -s\n";
    return -1;
  }

  if (ToBinary || ToText)
    return convertSPRV();

  if (!IsReverse && !IsRegularization)
    return convertLLVMToSPRV();

  if (IsReverse && IsRegularization) {
    errs() << "Cannot have both -r and -s options\n";
    return -1;
  }
  if (IsReverse)
    return convertSPRVToLLVM();

  if (IsRegularization)
    return regularizeLLVM();
}
