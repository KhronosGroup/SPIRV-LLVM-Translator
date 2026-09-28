// Test helper for layouts computed by LLVM TargetParser.
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/TargetParser/Triple.h"

#include <string>

using namespace llvm;

static cl::opt<std::string> Input(cl::Positional, cl::Required,
                                  cl::desc("<LLVM IR or bitcode>"));
static cl::opt<std::string> TargetTriple("triple", cl::Required,
                                         cl::desc("Expected target triple"));
static cl::opt<unsigned>
    ProgramAddressSpace("program-address-space",
                        cl::desc("Expected program address space override"));

int main(int argc, char **argv) {
  cl::ParseCommandLineOptions(argc, argv,
                              "Check an LLVM-derived target layout\n");
  LLVMContext Context;
  SMDiagnostic Diagnostic;
  auto M = parseIRFile(Input, Diagnostic, Context);
  if (!M) {
    Diagnostic.print(argv[0], errs());
    return 1;
  }

  std::string Expected = Triple(TargetTriple).computeDataLayout();
  if (Expected.empty()) {
    errs() << "No data layout for target triple '" << TargetTriple << "'\n";
    return 1;
  }
  if (ProgramAddressSpace.getNumOccurrences())
    Expected += "-P" + std::to_string(ProgramAddressSpace);

  if (M->getDataLayoutStr() != Expected) {
    errs() << "Target data layout mismatch\nExpected: " << Expected
           << "\nActual:   " << M->getDataLayoutStr() << '\n';
    return 1;
  }
  return 0;
}
