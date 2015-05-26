//===-- llvm-bil.cpp - The LLVM/SPIRV translator utility -----*- C++ -*-===//
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
//
//  Common Usage:
//  llvm-bil          - Read LLVM bitcode from stdin, write SPIRV to stdout
//  llvm-bil x.bc     - Read LLVM bitcode from the x.bc file, write SPIRV to x.bil file
//  llvm-bil -r       - Read SPIRV from stdin, write LLVM bitcode to stdout
//  llvm-bil -r x.bil - Read SPIRV from the x.bil file, write SPIRV to the x.bc file
//
//  Options:
//      --help   - Output command line options
//
//===----------------------------------------------------------------------===//

#include "llvm/IR/LLVMContext.h"
#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
#include "llvm/Support/FileSystem.h"
#include "llvm/IR/Verifier.h"
#else
#include "llvm/ADT/OwningPtr.h"
#include "llvm/Analysis/Verifier.h"
#endif
#include "llvm/Bitcode/ReaderWriter.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/DataStream.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/ToolOutputFile.h"
#include "../../lib/SPIRV/SPRVDebug.h"
#include "../../lib/SPIRV/SPRVError.h"
#include "../../lib/SPIRV/LLVMSPRV.h"

#include <memory>
#include <fstream>

using namespace llvm;
using namespace SPRV;

static cl::opt<std::string>
InputFile(cl::Positional, cl::desc("<input file>"), cl::init("-"));

static cl::opt<std::string>
OutputFile("o", cl::desc("Override output filename"),
               cl::value_desc("filename"));

static cl::opt<bool>
IsReverse("r", cl::desc("Reverse translation (SPRV to LLVM)"));

static cl::opt<bool>
IsRegularization("s", cl::desc("Regularize LLVM to be representable by SPRV"));

#ifdef _SPRVDBG
static cl::opt<bool, true>
UseTextFormat("t", cl::desc("Use text format for SPIRV for debugging purpose"),
    cl::location(SPRV::SPRVDbgUseTextFormat));

static cl::opt<bool, true>
EnableDbgOutput("d", cl::desc("Enable debug output"),
    cl::location(SPRV::SPRVDbgEnable));
#endif

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

  SPRVErrorCode ErrCode;
  std::string Err;
  DataStreamer *DS = getDataFileStreamer(InputFile, &Err);
  if (!DS) {
    errs() << "Fails to open input file: " << Err;
    return -1;
  }

#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
  ErrorOr<std::unique_ptr<Module>> MOrErr =
    getStreamedBitcodeModule(InputFile, DS, Context);
  std::unique_ptr<Module> M(std::move(*MOrErr));
#else
  OwningPtr<Module> M(getStreamedBitcodeModule(InputFile, DS,
      Context, &Err));
#endif
  if (!M) {
    errs() << "Fails to load bitcode: " << Err;
    return -1;
  }

#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
  if (std::error_code EC = M->materializeAllPermanently()){
    errs() << "Fails to materialize: " << EC.message();
#else
  if (M->MaterializeAllPermanently(&Err)){
    errs() << "Fails to materialize: " << Err;
#endif
    return -1;
  }

  if (OutputFile.empty()) {
    if (InputFile == "-")
      OutputFile = "-";
    else
      OutputFile = removeExt(InputFile) + ".bil";
  }

  std::ofstream OFS(OutputFile, std::ios::binary);
  if (!WriteSPRV(M.get(), OFS, ErrCode, Err)) {
    errs() << "Fails to save LLVM as SPRV: " << Err << '\n';
    return ErrCode;
  }
  return 0;
}

static int
convertSPRVToLLVM() {
  LLVMContext Context;
  std::ifstream IFS(InputFile, std::ios::binary);
  Module *M;
  SPRVErrorCode ErrCode;
  std::string Err;

  if (!ReadSPRV(Context, IFS, M, ErrCode, Err)) {
    errs() << "Fails to load SPIRV as LLVM Module: " << Err << '\n';
    return ErrCode;
  }

  SPRVDBG(dbgs() << "Converted LLVM module:\n" << *M);


#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
  raw_string_ostream ErrorOS(Err);
  if (verifyModule(*M, &ErrorOS)){
#else
  if (verifyModule(*M, ReturnStatusAction, &Err)){
#endif
    errs() << "Fails to verify module: " << Err;
    return -1;
  }

  if (OutputFile.empty()) {
    if (InputFile == "-")
      OutputFile = "-";
    else
      OutputFile = removeExt(InputFile) + ".bc";
  }

#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
  std::error_code EC;
  tool_output_file Out(OutputFile.c_str(), EC, sys::fs::F_None);
  if (EC) {
    errs() << "Fails to open output file: " << EC.message();
    return -1;
  }

  WriteBitcodeToFile(M, Out.os());
  Out.keep();
#else
  OwningPtr<tool_output_file> Out(new tool_output_file(OutputFile.c_str(), Err,
      sys::fs::F_Binary));
  if (!Err.empty()) {
    errs() << "Fails to open output file: " << Err;
    return -1;
  }

  WriteBitcodeToFile(M, Out->os());
  Out->keep();
#endif
  delete M;
  return 0;
}

static int
regularizeLLVM() {
  LLVMContext Context;

  SPRVErrorCode ErrCode;
  std::string Err;
  DataStreamer *DS = getDataFileStreamer(InputFile, &Err);
  if (!DS) {
    errs() << "Fails to open input file: " << Err;
    return -1;
  }

#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
  ErrorOr<std::unique_ptr<Module>> MOrErr =
    getStreamedBitcodeModule(InputFile, DS, Context);
  std::unique_ptr<Module> M(std::move(*MOrErr));
#else
  OwningPtr<Module> M(getStreamedBitcodeModule(InputFile, DS,
    Context, &Err));
#endif
  if (!M) {
    errs() << "Fails to load bitcode: " << Err;
    return -1;
  }

#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
  if (std::error_code EC = M->materializeAllPermanently()){
    errs() << "Fails to materialize: " << EC.message();
#else
  if (M->MaterializeAllPermanently(&Err)){
    errs() << "Fails to materialize: " << Err;
#endif
    return -1;
  }

  if (OutputFile.empty()) {
    if (InputFile == "-")
      OutputFile = "-";
    else
      OutputFile = removeExt(InputFile) + ".regularized.bc";
  }

  if (!RegularizeLLVMForSPRV(M.get(), ErrCode, Err)) {
    errs() << "Fails to save LLVM as SPRV: " << Err << '\n';
    return ErrCode;
  }

#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
  std::error_code EC;
  tool_output_file Out(OutputFile.c_str(), EC, sys::fs::F_None);
  if (EC) {
    errs() << "Fails to open output file: " << EC.message();
    return -1;
  }

  WriteBitcodeToFile(M.get(), Out.os());
  Out.keep();
#else
  OwningPtr<tool_output_file> Out(new tool_output_file(OutputFile.c_str(), Err,
    sys::fs::F_Binary));
  if (!Err.empty()) {
    SPRVDBG(errs() << "Fails to open output file: " << Err;)
    return -1;
  }

  WriteBitcodeToFile(M.get(), Out->os());
  Out->keep();
#endif
  return 0;
}


int
main(int ac, char** av) {
  cl::ParseCommandLineOptions(ac, av, "LLVM/SPRV translator");

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
