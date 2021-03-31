//===- SPIRVMemAliasingINTEL.h -                               --*- C++ -*-===//
//
//                     The LLVM/SPIRV Translator
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
/// \file
///
/// This file defines the memory aliasing entries defined in SPIRV spec with op
/// codes.
///
//===----------------------------------------------------------------------===//

#ifndef SPIRV_LIBSPIRV_SPIRVMEMALIASINGINTEL_H
#define SPIRV_LIBSPIRV_SPIRVMEMALIASINGINTEL_H

#include "SPIRVEntry.h"

namespace SPIRV {

template <Op TheOpCode, SPIRVWord TheFixedWordCount>
class SPIRVMemAliasingINTELGeneric : public SPIRVEntry {
public:
  SPIRVMemAliasingINTELGeneric(SPIRVModule *TheModule, SPIRVId TheId,
                               const std::vector<SPIRVId> &TheArgs)
      : SPIRVEntry(TheModule, TheArgs.size() + TheFixedWordCount, TheOpCode,
                   TheId), Args(TheArgs) {
    SPIRVMemAliasingINTELGeneric::validate();
    assert(TheModule && "Invalid module");
  }

  SPIRVMemAliasingINTELGeneric() : SPIRVEntry(TheOpCode) {}

  void setArguments(const std::vector<SPIRVId> &A) {
    Args = A;
    setWordCount(Args.size() + TheFixedWordCount);
  }

  const std::vector<SPIRVId> &getArguments() const { return Args; }

  std::vector<SPIRVValue *> getArgumentValues() { return getValues(Args); }

  void setWordCount(SPIRVWord TheWordCount) override {
    SPIRVEntry::setWordCount(TheWordCount);
    Args.resize(TheWordCount - TheFixedWordCount);
  }

  void validate() const override { SPIRVEntry::validate(); }

  SPIRVCapVec getRequiredCapability() const override {
    return getVec(internal::CapabilityMemoryAccessAliasingINTEL);
  }

  llvm::Optional<ExtensionID> getRequiredExtension() const override {
    return ExtensionID::SPV_INTEL_memory_access_aliasing;
  }

protected:
  static const SPIRVWord FixedWC = TheFixedWordCount;
  static const Op OC = TheOpCode;
  std::vector<SPIRVId> Args;
  _SPIRV_DEF_ENCDEC2(Id, Args)
};

#define _SPIRV_OP(x, ...)                                                      \
  typedef SPIRVMemAliasingINTELGeneric<internal::Op##x, __VA_ARGS__> SPIRV##x;
// Intel Mem Alasing Instructions
_SPIRV_OP(AliasDomainDeclINTEL, 2)
_SPIRV_OP(AliasScopeDeclINTEL, 2)
_SPIRV_OP(AliasScopeListDeclINTEL, 2)
#undef _SPIRV_OP

} // SPIRV
#endif // SPIRV_LIBSPIRV_SPIRVMEMALIASINGINTEL_H
