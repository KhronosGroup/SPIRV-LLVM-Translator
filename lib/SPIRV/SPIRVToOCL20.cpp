//===- SPIRVToOCL20.cpp - Transform SPIR-V builtins to OCL20 builtins-------===//
//
//                     The LLVM/SPIRV Translator
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
// Copyright (c) 2014 Advanced Micro Devices, Inc. All rights reserved.
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
// This file implements transform SPIR-V builtins to OCL 2.0 builtins.
//
//===----------------------------------------------------------------------===//
#define DEBUG_TYPE "spvtocl20"

#include "SPIRVInternal.h"
#include "OCLUtil.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Pass.h"
#include "llvm/PassSupport.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"

#include <cstring>

using namespace llvm;
using namespace SPIRV;
using namespace OCLUtil;

namespace SPIRV {

static cl::opt<std::string>
MangledAtomicTypeNamePrefix("spirv-atomic-prefix",
    cl::desc("Mangled atomic type name prefix"), cl::init("U7_Atomic"));

class SPIRVToOCL20: public ModulePass,
  public InstVisitor<SPIRVToOCL20> {
public:
  SPIRVToOCL20():ModulePass(ID), M(nullptr), Ctx(nullptr) {
    initializeSPIRVToOCL20Pass(*PassRegistry::getPassRegistry());
  }
  virtual bool runOnModule(Module &M);
  virtual void visitCallInst(CallInst &CI);

  /// Transform __spirv_ImageQuerySize[Lod] into vector of the same lenght
  /// containing {[get_image_width | get_image_dim], get_image_array_size}
  /// for all images except image1d_t which is always converted into
  /// get_image_width returning scalar result.
  void visitCallSPRIVImageQuerySize(CallInst *CI);

  /// Transform __spirv_Atomic* to atomic_*.
  ///   __spirv_Atomic*(atomic_op, scope, sema, ops, ...) =>
  ///      atomic_*(atomic_op, ops, ..., order(sema), map(scope))
  void visitCallSPIRVAtomicBuiltin(CallInst *CI, Op OC);

  /// Transform __spirv_Group* to {work_group|sub_group}_*.
  ///
  /// Special handling of work_group_broadcast.
  ///   __spirv_GroupBroadcast(a, vec3(x, y, z))
  ///     =>
  ///   work_group_broadcast(a, x, y, z)
  ///
  /// Transform OpenCL group builtin function names from group_
  /// to workgroup_ and sub_group_.
  /// Insert group operation part: reduce_/inclusive_scan_/exclusive_scan_
  /// Transform the operation part:
  ///    fadd/iadd/sadd => add
  ///    fmax/smax => max
  ///    fmin/smin => min
  /// Keep umax/umin unchanged.
  void visitCallSPIRVGroupBuiltin(CallInst *CI, Op OC);

  /// Transform __spirv_MemoryBarrier to atomic_work_item_fence.
  ///   __spirv_MemoryBarrier(scope, sema) =>
  ///       atomic_work_item_fence(flag(sema), order(sema), map(scope))
  void visitCallSPIRVMemoryBarrier(CallInst *CI);

  /// Transform __spirv_{PipeOpName} to OCL pipe builtin functions.
  void visitCallSPIRVPipeBuiltin(CallInst *CI, Op OC);

  /// Transform __spirv_* builtins to OCL 2.0 builtins.
  /// No change with arguments.
  void visitCallSPIRVBuiltin(CallInst *CI, Op OC);

  /// Translate mangled atomic type name: "atomic_" =>
  ///   MangledAtomicTypeNamePrefix
  void translateMangledAtomicTypeName();

  /// Get prefix work_/sub_ for OCL group builtin functions.
  /// Assuming the first argument of \param CI is a constant integer for
  /// workgroup/subgroup scope enums.
  std::string getGroupBuiltinPrefix(CallInst *CI);

  static char ID;
private:
  Module *M;
  LLVMContext *Ctx;
};

char SPIRVToOCL20::ID = 0;

bool
SPIRVToOCL20::runOnModule(Module& Module) {
  M = &Module;
  Ctx = &M->getContext();
  visit(*M);

  translateMangledAtomicTypeName();

  eraseUselessFunctions(&Module);

  DEBUG(dbgs() << "After SPIRVToOCL20:\n" << *M);

  std::string Err;
  raw_string_ostream ErrorOS(Err);
  if (verifyModule(*M, &ErrorOS)){
    DEBUG(errs() << "Fails to verify module: " << ErrorOS.str());
  }
  return true;
}

void
SPIRVToOCL20::visitCallInst(CallInst& CI) {
  DEBUG(dbgs() << "[visistCallInst] " << CI << '\n');
  auto F = CI.getCalledFunction();
  if (!F)
    return;

  auto MangledName = F->getName();
  std::string DemangledName;
  Op OC = OpNop;
  if (!oclIsBuiltin(MangledName, 20, &DemangledName) ||
      (OC = getSPIRVFuncOC(DemangledName)) == OpNop)
    return;
  DEBUG(dbgs() << "DemangledName = " << DemangledName.c_str() << '\n'
               << "OpCode = " << OC << '\n');

  if (OC == OpImageQuerySize || OC == OpImageQuerySizeLod) {
    visitCallSPRIVImageQuerySize(&CI);
    return;
  }
  if (OC == OpMemoryBarrier) {
    visitCallSPIRVMemoryBarrier(&CI);
    return;
  }
  if (isAtomicOpCode(OC)) {
    visitCallSPIRVAtomicBuiltin(&CI, OC);
    return;
  }
  if (isGroupOpCode(OC)) {
    visitCallSPIRVGroupBuiltin(&CI, OC);
    return;
  }
  if (isPipeOpCode(OC)) {
    visitCallSPIRVPipeBuiltin(&CI, OC);
    return;
  }
  if (OCLSPIRVBuiltinMap::rfind(OC))
    visitCallSPIRVBuiltin(&CI, OC);

}

void SPIRVToOCL20::visitCallSPIRVMemoryBarrier(CallInst* CI) {
  AttributeSet Attrs = CI->getCalledFunction()->getAttributes();
  mutateCallInstOCL(M, CI, [=](CallInst *, std::vector<Value *> &Args){
    auto getArg = [=](unsigned I){
      return cast<ConstantInt>(Args[I])->getZExtValue();
    };
    auto MScope = static_cast<Scope>(getArg(0));
    auto Sema = mapSPIRVMemSemanticToOCL(getArg(1));
    Args.resize(3);
    Args[0] = getInt32(M, Sema.first);
    Args[1] = getInt32(M, Sema.second);
    Args[2] = getInt32(M, rmap<OCLScopeKind>(MScope));
    return kOCLBuiltinName::AtomicWorkItemFence;
  }, &Attrs);
}

void SPIRVToOCL20::visitCallSPRIVImageQuerySize(CallInst *CI) {
  Function * func = CI->getCalledFunction();
  // Get image type
  Type * argTy = func->getFunctionType()->getParamType(0);
  assert(argTy->isPointerTy() && "argument must be a pointer to opaque structure");
  StructType * imgTy = cast<StructType>(argTy->getPointerElementType());
  assert(imgTy->isOpaque() && "image type must be an opaque structure");
  StringRef imgTyName = imgTy->getName();

  unsigned imgDim = 0;
  bool imgArray = false;

  if (imgTyName.startswith("opencl.image1d")) {
    imgDim = 1;
  } else if (imgTyName.startswith("opencl.image2d")) {
    imgDim = 2;
  } else if (imgTyName.startswith("opencl.image3d")) {
    imgDim = 3;
  }

  if (imgTyName.startswith("opencl.image") &&
      imgTyName.count("_array_t") > 0) {
    imgArray = true;
  }

  AttributeSet attributes = CI->getCalledFunction()->getAttributes();
  BuiltinFuncMangleInfo mangle;
  Type * int32Ty = Type::getInt32Ty(*Ctx);
  Instruction * getImageSize = nullptr;

  if (imgDim == 1) {
    // OpImageQuerySize from non-arrayed 1d image is always translated
    // into get_image_width returning scalar argument
    getImageSize =
      addCallInst(M, kOCLBuiltinName::GetImageWidth, int32Ty,
                  CI->getArgOperand(0), &attributes,
                  CI, &mangle, CI->getName(), false);
    // The width of integer type returning by OpImageQuerySize[Lod] may
    // differ from i32
    if (CI->getType()->getScalarType() != int32Ty) {
      getImageSize =
        CastInst::CreateIntegerCast(getImageSize, CI->getType()->getScalarType(), false,
                                    CI->getName(), CI);
    }
  } else {
    assert((imgDim == 2 || imgDim == 3) && "invalid image type");
    assert(CI->getType()->isVectorTy() && "this code can handle vector result type only");
    // get_image_dim returns int2 and int4 for 2d and 3d images respecitvely.
    const unsigned imgDimRetEls = imgDim == 2 ? 2 : 4;
    VectorType * retTy = VectorType::get(int32Ty, imgDimRetEls);
    getImageSize =
      addCallInst(M, kOCLBuiltinName::GetImageDim, retTy,
                  CI->getArgOperand(0), &attributes,
                  CI, &mangle, CI->getName(), false);
    // The width of integer type returning by OpImageQuerySize[Lod] may
    // differ from i32
    if (CI->getType()->getScalarType() != int32Ty) {
      getImageSize =
        CastInst::CreateIntegerCast(getImageSize,
                                    VectorType::get(CI->getType()->getScalarType(),
                                                    getImageSize->getType()->getVectorNumElements()),
                                    false, CI->getName(), CI);
    }
  }

  if (imgArray || imgDim == 3) {
    assert(CI->getType()->isVectorTy() &&
           "OpImageQuerySize[Lod] must return vector for arrayed and 3d images");
    const unsigned imgQuerySizeRetEls = CI->getType()->getVectorNumElements();

    if (imgDim == 1) {
      // get_image_width returns scalar result while OpImageQuerySize
      // for image1d_array_t returns <2 x i32> vector.
      assert(imgQuerySizeRetEls == 2 &&
             "OpImageQuerySize[Lod] must return <2 x iN> vector type");
      getImageSize =
        InsertElementInst::Create(UndefValue::get(CI->getType()), getImageSize,
                                  ConstantInt::get(int32Ty, 1), CI->getName(), CI);
    } else {
      // get_image_dim and OpImageQuerySize returns different vector
      // types for arrayed and 3d images.
      SmallVector<Constant*, 4> maskEls;
      for(unsigned idx = 0; idx < imgQuerySizeRetEls; ++idx)
        maskEls.push_back(ConstantInt::get(int32Ty, idx));
      Constant * mask = ConstantVector::get(maskEls);

      getImageSize =
        new ShuffleVectorInst(getImageSize, UndefValue::get(getImageSize->getType()),
                              mask, CI->getName(), CI);
    }
  }

  if (imgArray) {
    assert((imgDim == 1 || imgDim == 2) && "invalid image array type");
    // Insert get_image_array_size to the last position of the resulting vector.
    Type * sizeTy = Type::getIntNTy(*Ctx, M->getDataLayout()->getPointerSizeInBits(0));
    Instruction * getImageArraySize =
      addCallInst(M, kOCLBuiltinName::GetImageArraySize, sizeTy,
                  CI->getArgOperand(0), &attributes,
                  CI, &mangle, CI->getName(), false);
    // The width of integer type returning by OpImageQuerySize[Lod] may
    // differ from size_t which is returned by get_image_array_size
    if (getImageArraySize->getType() != CI->getType()->getScalarType()) {
      getImageArraySize =
        CastInst::CreateIntegerCast(getImageArraySize, CI->getType()->getScalarType(),
                                    false, CI->getName(), CI);
    }
    getImageSize =
      InsertElementInst::Create(getImageSize, getImageArraySize,
                                ConstantInt::get(int32Ty,
                                                 CI->getType()->getVectorNumElements() - 1),
                                CI->getName(), CI);
  }

  assert(getImageSize && "must not be null");
  CI->replaceAllUsesWith(getImageSize);
  CI->eraseFromParent();
}

void SPIRVToOCL20::visitCallSPIRVAtomicBuiltin(CallInst* CI, Op OC) {
  AttributeSet Attrs = CI->getCalledFunction()->getAttributes();
  mutateCallInstOCL(M, CI, [=](CallInst *, std::vector<Value *> &Args){
    auto Ptr = findFirstPtr(Args);
    auto Name = OCLSPIRVBuiltinMap::rmap(OC);
    auto NumOrder = getAtomicBuiltinNumMemoryOrderArgs(Name);
    auto OrderIdx = Ptr + 1;
    auto ScopeIdx = Ptr + 1 + NumOrder;
    if (OC == OpAtomicIIncrement ||
        OC == OpAtomicIDecrement) {
      Args.erase(Args.begin() + OrderIdx, Args.begin() + ScopeIdx + 1);
    } else {
      Args[ScopeIdx] = mapUInt(M, cast<ConstantInt>(Args[ScopeIdx]),
          [](unsigned I){
        return rmap<OCLScopeKind>(static_cast<Scope>(I));
      });
      for (size_t I = 0; I < NumOrder; ++I)
        Args[OrderIdx + I] = mapUInt(M, cast<ConstantInt>(Args[OrderIdx + I]),
            [](unsigned Ord) {
        return mapSPIRVMemOrderToOCL(Ord);
      });
      move(Args, OrderIdx, ScopeIdx + 1, Args.size());
    }
    return Name;
  }, &Attrs);
}

void SPIRVToOCL20::visitCallSPIRVBuiltin(CallInst* CI, Op OC) {
  AttributeSet Attrs = CI->getCalledFunction()->getAttributes();
  mutateCallInstOCL(M, CI, [=](CallInst *, std::vector<Value *> &Args){
    return OCLSPIRVBuiltinMap::rmap(OC);
  }, &Attrs);
}

void SPIRVToOCL20::visitCallSPIRVGroupBuiltin(CallInst* CI, Op OC) {
  auto DemangledName = OCLSPIRVBuiltinMap::rmap(OC);
  assert(DemangledName.find(kSPIRVName::GroupPrefix) == 0);

  std::string Prefix = getGroupBuiltinPrefix(CI);

  bool HasGroupOperation = hasGroupOperation(OC);
  if (!HasGroupOperation) {
    DemangledName = Prefix + DemangledName;
  } else {
    auto GO = getArgAs<spv::GroupOperation>(CI, 1);
    StringRef Op = DemangledName;
    Op = Op.drop_front(strlen(kSPIRVName::GroupPrefix));
    bool Unsigned = Op.front() == 'u';
    if (!Unsigned)
      Op = Op.drop_front(1);
    DemangledName = Prefix + kSPIRVName::GroupPrefix +
        SPIRSPIRVGroupOperationMap::rmap(GO) + '_' + Op.str();
  }
  AttributeSet Attrs = CI->getCalledFunction()->getAttributes();
  mutateCallInstOCL(M, CI, [=](CallInst *, std::vector<Value *> &Args){
    Args.erase(Args.begin(), Args.begin() + (HasGroupOperation ? 2 : 1));
    if (OC == OpGroupBroadcast)
      expandVector(CI, Args, 1);
    return DemangledName;
  }, &Attrs);
}

void SPIRVToOCL20::visitCallSPIRVPipeBuiltin(CallInst* CI, Op OC) {
  switch(OC) {
  case OpReservedReadPipe:
    OC = OpReadPipe;
    break;
  case OpReservedWritePipe:
    OC = OpWritePipe;
    break;
  default:
    // Do nothing.
    break;
  }
  auto DemangledName = OCLSPIRVBuiltinMap::rmap(OC);

  bool HasScope = DemangledName.find(kSPIRVName::GroupPrefix) == 0;
  if (HasScope)
    DemangledName = getGroupBuiltinPrefix(CI) + DemangledName;

  AttributeSet Attrs = CI->getCalledFunction()->getAttributes();
  mutateCallInstOCL(M, CI, [=](CallInst *, std::vector<Value *> &Args){
    if (HasScope)
      Args.erase(Args.begin(), Args.begin() + 1);

    if (!(OC == OpReadPipe ||
          OC == OpWritePipe ||
          OC == OpReservedReadPipe ||
          OC == OpReservedWritePipe))
      return DemangledName;

    auto &P = Args[Args.size() - 3];
    auto T = P->getType();
    assert(isa<PointerType>(T));
    auto ET = T->getPointerElementType();
    if (!ET->isIntegerTy(8) ||
        T->getPointerAddressSpace() != SPIRAS_Generic) {
      auto NewTy = PointerType::getInt8PtrTy(*Ctx, SPIRAS_Generic);
      P = CastInst::CreatePointerBitCastOrAddrSpaceCast(P, NewTy, "", CI);
    }
    return DemangledName;
  }, &Attrs);
}

void SPIRVToOCL20::translateMangledAtomicTypeName() {
  for (auto &I:M->functions()) {
    if (!I.hasName())
      continue;
    std::string MangledName = I.getName();
    std::string DemangledName;
    if (!oclIsBuiltin(MangledName, 20, &DemangledName) ||
        DemangledName.find(kOCLBuiltinName::AtomPrefix) != 0)
      continue;
    auto Loc = MangledName.find(kOCLBuiltinName::AtomPrefix);
    Loc = MangledName.find(kMangledName::AtomicPrefixInternal, Loc);
    MangledName.replace(Loc, strlen(kMangledName::AtomicPrefixInternal),
        MangledAtomicTypeNamePrefix);
    I.setName(MangledName);
  }
}

std::string
SPIRVToOCL20::getGroupBuiltinPrefix(CallInst* CI) {
  std::string Prefix;
  auto ES = getArgAsScope(CI, 0);
  switch(ES) {
  case ScopeWorkgroup:
    Prefix = kOCLBuiltinName::WorkPrefix;
    break;
  case ScopeSubgroup:
    Prefix = kOCLBuiltinName::SubPrefix;
    break;
  default:
    llvm_unreachable("Invalid execution scope");
  }
  return Prefix;
}

}

INITIALIZE_PASS(SPIRVToOCL20, "spvtoocl20",
    "Translate SPIR-V builtins to OCL 2.0 builtins", false, false)

ModulePass *llvm::createSPIRVToOCL20() {
  return new SPIRVToOCL20();
}
