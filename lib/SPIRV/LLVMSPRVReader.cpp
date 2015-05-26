//===- LLVMSPRVReader.cpp – Converts SPIRV to LLVM -----------------*- C++ -*-===//
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
// This file implements conversion of SPIRV binary to LLVM intermediate language.
//
//===----------------------------------------------------------------------===//

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/Type.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/Debug.h"
#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
#include "llvm/Support/FileSystem.h"
#endif
#include "llvm/Support/raw_ostream.h"

#include "SPRVUtil.h"
#include "SPRVType.h"
#include "SPRVValue.h"
#include "SPRVModule.h"
#include "SPRVFunction.h"
#include "SPRVBasicBlock.h"
#include "SPRVInstruction.h"
#include "SPRVBuiltin.h"
#include "LLVMSPRVInternal.h"
#include "spir_name_mangler/NameMangleAPI.h"

#include <cstdlib>
#include <functional>
#include <fstream>
#include <strstream>
#include <map>
#include <set>
#include <iostream>
using namespace std;

using namespace llvm;
using namespace SPRV;

namespace SPRV{

// Prefix for placeholder global variable name.
const char* kPlaceholderPrefix = "placeholder.";

// Save the translated LLVM before validation for debugging purpose.
static bool DbgSaveTmpLLVM = true;
static const char *DbgTmpLLVMFileName = "_tmp_llvmbil.ll";

typedef std::pair < unsigned, AttributeSet > AttributeWithIndex;

static std::vector<AttributeWithIndex>
getAttrVec(const AttributeSet &PAL) {
  std::vector<AttributeWithIndex> AttrVec;
  for (unsigned I = 0, E = PAL.getNumSlots(); I != E; ++I){
    AttrVec.push_back(std::make_pair(PAL.getSlotIndex(I), PAL.getSlotAttributes(I)));
  }
  return AttrVec;
}

// Translated uniqued OCL builtin name to its original name, and set
// argument attributes and unsigned args.
static void
getOCLBuiltinArgInfo(std::string& UnmangledName,
    std::set<int> &UnsignedArgs, unsigned& Attr) {
  if (UnmangledName.find("write_imageui") == 0)
      UnsignedArgs.insert(2);
  else if (UnmangledName.find("get_") == 0 ||
      UnmangledName.find("barrier") == 0 ||
      UnmangledName.find("vload") == 0 ||
      UnmangledName.find("vstore") == 0 ||
      UnmangledName.find("async_work_group") == 0 ||
      UnmangledName == "prefetch" ||
      UnmangledName == "nan" ||
      UnmangledName.find("shuffle") == 0)
    UnsignedArgs.insert(-1);
  else if (UnmangledName.find("atomic") == 0) {
    Attr = SPIR::ATTR_VOLATILE;
    if (UnmangledName == "atomic_umax" ||
        UnmangledName == "atomic_umin") {
      UnsignedArgs.insert(-1);
      UnmangledName.erase(7, 1);
    }
  } else if (UnmangledName.find("uconvert_") == 0) {
    UnsignedArgs.insert(0);
    UnmangledName.erase(0, 1);
  } else if (UnmangledName.find("s_") == 0) {
    UnmangledName.erase(0, 2);
  } else if (UnmangledName.find("u_") == 0) {
    UnsignedArgs.insert(-1);
    UnmangledName.erase(0, 2);
  }
}

static bool
isOpenCLKernel(SPRVFunction *BF) {
  return BF->getModule()->isEntryPoint(SPRVEMDL_Kernel, BF->getId());
}

//ToDo: add translation of all LLVM types
static SPIR::RefParamType
transTypeDesc(Type *Ty, bool Signed = true, unsigned Attr = 0) {
  if(auto *IntTy = dyn_cast<IntegerType>(Ty)) {
    switch(IntTy->getBitWidth()) {
    case 8:
      return SPIR::RefParamType(new SPIR::PrimitiveType(Signed?
          SPIR::PRIMITIVE_CHAR:SPIR::PRIMITIVE_UCHAR));
    case 16:
      return SPIR::RefParamType(new SPIR::PrimitiveType(Signed?
          SPIR::PRIMITIVE_SHORT:SPIR::PRIMITIVE_USHORT));
    case 32:
      return SPIR::RefParamType(new SPIR::PrimitiveType(Signed?
          SPIR::PRIMITIVE_INT:SPIR::PRIMITIVE_UINT));
    case 64:
      return SPIR::RefParamType(new SPIR::PrimitiveType(Signed?
          SPIR::PRIMITIVE_LONG:SPIR::PRIMITIVE_ULONG));
    default:
      assert(0 && "invliad int size");
    }
  }
  if (Ty->isHalfTy())
    return SPIR::RefParamType(new SPIR::PrimitiveType(SPIR::PRIMITIVE_HALF));
  if (Ty->isFloatTy())
    return SPIR::RefParamType(new SPIR::PrimitiveType(SPIR::PRIMITIVE_FLOAT));
  if (Ty->isDoubleTy())
    return SPIR::RefParamType(new SPIR::PrimitiveType(SPIR::PRIMITIVE_DOUBLE));
  if (Ty->isVectorTy()) {
    return SPIR::RefParamType(new SPIR::VectorType(
        transTypeDesc(Ty->getVectorElementType(), Signed),
        Ty->getVectorNumElements()));
  }
  if (Ty->isPointerTy()) {
    if (auto StructTy = dyn_cast<StructType>(Ty->getPointerElementType())) {
      SPRVDBG(dbgs() << "ptr to struct: " << *Ty << '\n');
      assert (StructTy->isOpaque() && "Invalid type");
#define _SPRV_OP(x,y) .Case("opencl."#x"_t", SPIR::PRIMITIVE_##y##_T)
      return SPIR::RefParamType(new SPIR::PrimitiveType(
          StringSwitch<SPIR::TypePrimitiveEnum>(StructTy->getStructName())
          _SPRV_OP(image1d, IMAGE_1D)
          _SPRV_OP(image1d_array, IMAGE_1D_ARRAY)
          _SPRV_OP(image1d_buffer, IMAGE_1D_BUFFER)
          _SPRV_OP(image2d, IMAGE_2D)
          _SPRV_OP(image2d_array, IMAGE_2D_ARRAY)
          _SPRV_OP(image3d, IMAGE_3D)
          _SPRV_OP(image2d_msaa, IMAGE_2D_MSAA)
          _SPRV_OP(image2d_array_msaa, IMAGE_2D_ARRAY_MSAA)
          _SPRV_OP(image2d_msaa_depth, IMAGE_2D_MSAA_DEPTH)
          _SPRV_OP(image2d_array_msaa_depth, IMAGE_2D_ARRAY_MSAA_DEPTH)
          _SPRV_OP(image2d_depth, IMAGE_2D_DEPTH)
          _SPRV_OP(image2d_array_depth, IMAGE_2D_ARRAY_DEPTH)
          _SPRV_OP(event, EVENT)
          _SPRV_OP(pipe, PIPE)
          _SPRV_OP(reserve_id, RESERVE_ID)
          _SPRV_OP(queue, QUEUE)
          _SPRV_OP(ndrange, NDRANGE)
          _SPRV_OP(clk_event, CLK_EVENT)
          _SPRV_OP(sampler, SAMPLER)
          ));
#undef _SPRV_OP
    }
    auto PT = new SPIR::PointerType(transTypeDesc(
      Ty->getPointerElementType(), Signed));
    PT->setAddressSpace(static_cast<SPIR::TypeAttributeEnum>(
      Ty->getPointerAddressSpace() + (unsigned)SPIR::ATTR_ADDR_SPACE_FIRST));
    for (unsigned I = SPIR::ATTR_QUALIFIER_FIRST,
        E = SPIR::ATTR_QUALIFIER_LAST; I != E; ++I)
      PT->setQualifier(static_cast<SPIR::TypeAttributeEnum>(I), I & Attr);
    return SPIR::RefParamType(PT);
  }
  SPRVDBG(dbgs() << "[transTypeDesc] " << *Ty << '\n');
  assert (0 && "not implemented");
  return SPIR::RefParamType(new SPIR::PrimitiveType(SPIR::PRIMITIVE_INT));
}

// If SignedArgIndices contains -1, all integer arment is signed.
static void
mangle(SPRVExtInstSetKind BuiltinSet, const std::string &UnmangledName,
    ArrayRef<Type*> ArgTypes, std::string &MangledName) {
  assert(isOpenCLBuiltinSet(BuiltinSet) && "Not OpenCL builtin set");
  SPIR::NameMangler Mangler(BuiltinSet == SPRVBIS_OpenCL12 ? SPIR::SPIR12 :
      SPIR::SPIR20);
  SPIR::FunctionDescriptor FD;
  FD.name = UnmangledName;
  std::set<int> UnsignedArgs;
  unsigned Attr = 0;
  getOCLBuiltinArgInfo(FD.name, UnsignedArgs, Attr);
  for (unsigned I = 0, E = ArgTypes.size(); I != E; ++I) {
    FD.parameters.emplace_back(transTypeDesc(ArgTypes[I],
        !UnsignedArgs.count(-1) && !UnsignedArgs.count(I),
        Attr));
  }
  Mangler.mangle(FD, MangledName);
}

static void
dumpLLVM(Module *M, const std::string &FName) {
#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
  std::error_code EC;
  raw_fd_ostream FS(FName, EC, sys::fs::F_None);
  if (EC) {
    FS << *M;
    FS.close();
  }
#else
  std::string Err;
  raw_fd_ostream FS(FName.c_str(), Err);
  FS << *M;
  FS.close();
#endif
}

static MDNode*
getMDNodeStringIntVec(LLVMContext *Context, const std::string& Str,
    const std::vector<SPRVWord>& IntVals) {
#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
  std::vector<Metadata*> ValueVec;
#else
  std::vector<Value*> ValueVec;
#endif
  ValueVec.push_back(MDString::get(*Context, Str));
  for (auto &I:IntVals)
#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
    ValueVec.push_back(ConstantAsMetadata::get(ConstantInt::get(Type::getInt32Ty(*Context), I)));
#else
    ValueVec.push_back(ConstantInt::get(Type::getInt32Ty(*Context), I)); 
#endif
  return MDNode::get(*Context, ValueVec);
}

static MDNode*
getMDTwoInt(LLVMContext *Context, unsigned Int1, unsigned Int2) {
#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
  std::vector<Metadata*> ValueVec;
  ValueVec.push_back(ConstantAsMetadata::get(ConstantInt::get(Type::getInt32Ty(*Context), Int1)));
  ValueVec.push_back(ConstantAsMetadata::get(ConstantInt::get(Type::getInt32Ty(*Context), Int2)));
#else
  std::vector<Value*> ValueVec;
  ValueVec.push_back(ConstantInt::get(Type::getInt32Ty(*Context), Int1));
  ValueVec.push_back(ConstantInt::get(Type::getInt32Ty(*Context), Int2));
#endif
  return MDNode::get(*Context, ValueVec);
}

static MDNode*
getMDString(LLVMContext *Context, const std::string& Str) {
#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
  std::vector<Metadata*> ValueVec;
#else
  std::vector<Value*> ValueVec;
#endif
  if (!Str.empty())
    ValueVec.push_back(MDString::get(*Context, Str));
  return MDNode::get(*Context, ValueVec);
}

static void
addOCLVersionMetadata(LLVMContext *Context, Module *M,
    const std::string &MDName, unsigned Major, unsigned Minor) {
  NamedMDNode *NamedMD = M->getOrInsertNamedMetadata(MDName);
  NamedMD->addOperand(getMDTwoInt(Context, Major, Minor));
}

static void
addNamedMetadataString(LLVMContext *Context, Module *M,
    const std::string &MDName, const std::string &Str) {
  NamedMDNode *NamedMD = M->getOrInsertNamedMetadata(MDName);
  NamedMD->addOperand(getMDString(Context, Str));
}

static void
addOCLKernelArgumentMetadata(LLVMContext *Context,
#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
  std::vector<llvm::Metadata*> &KernelMD, const std::string &MDName,
    SPRVFunction *BF, std::function<Metadata *(SPRVFunctionParameter *)>Func){
  std::vector<Metadata*> ValueVec;
#else
  std::vector<llvm::Value*> &KernelMD, const std::string &MDName,
    SPRVFunction *BF, std::function<Value *(SPRVFunctionParameter *)>Func){
  std::vector<Value*> ValueVec;
#endif
    ValueVec.push_back(MDString::get(*Context, MDName));
  BF->foreachArgument([&](SPRVFunctionParameter *Arg) {
    ValueVec.push_back(Func(Arg));
  });
  KernelMD.push_back(MDNode::get(*Context, ValueVec));
}

class SPRVToLLVM {
public:
  SPRVToLLVM(Module *LLVMModule, SPRVModule *TheSPRVModule)
    :M(LLVMModule), BM(TheSPRVModule){
    if (M)
      Context = &M->getContext();
  }

  std::string getOCLBuiltinName(SPRVInstruction* BI);
  std::string getOCLConvertBuiltinName(SPRVInstruction *BI);

  Type *transType(SPRVType *BT);
  std::string transTypeToOCLTypeName(SPRVType *BT, bool IsSigned = true);
  std::vector<Type *> transTypeVector(const std::vector<SPRVType *>&);
  bool translate();
  bool transAddressingModel();

  Value *transValue(SPRVValue *, Function *F, BasicBlock *,
      bool CreatePlaceHolder = true);
  Value *transValueWithoutDecoration(SPRVValue *, Function *F, BasicBlock *,
      bool CreatePlaceHolder = true);
  bool transDecoration(SPRVValue *, Value *);
  bool transAlign(SPRVValue *, Value *);
  Instruction *transOCLBuiltinFromExtInst(SPRVExtInst *BC, BasicBlock *BB);
  std::vector<Value *> transValue(const std::vector<SPRVValue *>&, Function *F,
      BasicBlock *);
  Function *transFunction(SPRVFunction *F);
  bool transFPContractMetadata();
  bool transKernelMetadata();
  bool transSourceLanguage();
  bool transSourceExtension();
  bool transCompilerOption();
  Value *transConvertInst(SPRVValue* BV, Function* F, BasicBlock* BB);
  Instruction *transOCLBuiltinFromInst(const std::string& FuncName,
      SPRVInstruction* BI, BasicBlock* BB);
  Instruction *transOCLBuiltinFromInst(SPRVInstruction *BI, BasicBlock *BB);
  Instruction *transOCLAtomic(SPRVAtomicOperatorGeneric* BA, BasicBlock *BB);
  Instruction *transOCLBarrierFence(SPRVInstruction* BI, BasicBlock *BB);
  Instruction *transOCLDot(SPRVDot *BD, BasicBlock *BB);
  void transOCLVectorLoadStore(std::string& UnmangledName,
      std::vector<SPRVWord> &BArgs);

  typedef DenseMap<SPRVType *, Type *> SPRVToLLVMTypeMap;
  typedef DenseMap<SPRVValue *, Value *> SPRVToLLVMValueMap;
  typedef DenseMap<SPRVFunction *, Function *> SPRVToLLVMFunctionMap;
  typedef DenseMap<GlobalVariable *, SPRVBuiltinVariableKind> BuiltinVarMap;

  // A SPIRV value may be translated to a load instruction of a placeholder
  // global variable. This map records load instruction of these placeholders
  // which are supposed to be replaced by the real values later.
  typedef std::map<SPRVValue *, LoadInst*> SPRVToLLVMPlaceholderMap;
private:
  Module *M;
  BuiltinVarMap BuiltinGVMap;
  LLVMContext *Context;
  SPRVModule *BM;
  SPRVToLLVMTypeMap TypeMap;
  SPRVToLLVMValueMap ValueMap;
  SPRVToLLVMFunctionMap FuncMap;
  SPRVToLLVMPlaceholderMap PlaceholderMap;

  Type *mapType(SPRVType *BT, Type *T) {
    SPRVDBG(dbgs() << *T << '\n';)
    TypeMap[BT] = T;
    return T;
  }

  // If a value is mapped twice, the existing mapped value is a placeholder,
  // which must be a load instruction of a global variable whose name starts
  // with kPlaceholderPrefix.
  Value *mapValue(SPRVValue *BV, Value *V) {
    auto Loc = ValueMap.find(BV);
    if (Loc != ValueMap.end()) {
      if (Loc->second == V)
        return V;
      auto LD = dyn_cast<LoadInst>(Loc->second);
      auto Placeholder = dyn_cast<GlobalVariable>(LD->getPointerOperand());
      assert (LD && Placeholder &&
          Placeholder->getName().startswith(kPlaceholderPrefix) &&
          "A value is translated twice");
      // Replaces placeholders for PHI nodes
      LD->replaceAllUsesWith(V);
      LD->dropAllReferences();
      LD->removeFromParent();
      Placeholder->dropAllReferences();
      Placeholder->removeFromParent();
    }
    ValueMap[BV] = V;
    return V;
  }

  bool isSPRVBuiltinVariable(GlobalVariable *GV,
      SPRVBuiltinVariableKind *Kind = nullptr) {
    auto Loc = BuiltinGVMap.find(GV);
    if (Loc == BuiltinGVMap.end())
      return false;
    if (Kind)
      *Kind = Loc->second;
    return true;
  }
  // OpenCL function always has NoUnwound attribute.
  // Change this if it is no longer true.
  bool isFuncNoUnwind() const { return true;}
  bool isSPRVCmpInstTransToLLVMInst(SPRVInstruction *BI) const;
  bool transOCLBuiltinsFromVariables();
  bool transOCLBuiltinFromVariable(GlobalVariable *GV,
      SPRVBuiltinVariableKind Kind);
  MDString *transOCLKernelArgTypeName(SPRVFunctionParameter *);

  Value *mapFunction(SPRVFunction *BF, Function *F) {
    SPRVDBG(bildbgs() << "[mapFunction] " << *BF << " -> ";
      dbgs() << *F << '\n';)
    FuncMap[BF] = F;
    return F;
  }

  Value *getTranslatedValue(SPRVValue *BV);
  Type *getTranslatedType(SPRVType *BT);

  SPRVErrorLog &getErrorLog() {
    return BM->getErrorLog();
  }

  void setCallingConv(CallInst *Call) {
    Function *F = Call->getCalledFunction();
    Call->setCallingConv(F->getCallingConv());
  }

  void setAttrByCalledFunc(CallInst *Call);
  Type *transFPType(SPRVType* T);
  BinaryOperator *transShiftLogicalBitwiseInst(SPRVValue* BV, BasicBlock* BB,
      Function* F);
  void transFlags(llvm::Value* V);
  Instruction *transCmpInst(SPRVValue* BV, BasicBlock* BB, Function* F);
  void transOCLBuiltinFromInstPreproc(SPRVInstruction* BI, Type *&RetTy);
  Instruction* transOCLBuiltinFromInstPostproc(SPRVInstruction* BI,
      Instruction* Inst, BasicBlock* BB);
  std::string transOCLImageTypeName(SPRV::SPRVTypeSampler* ST);
  std::string transOCLImageTypeAccessQualifier(SPRV::SPRVTypeSampler* ST);
  Value *oclTransConstantSampler(SPRV::SPRVConstantSampler* BCS);
  template<class Source, class Func>
  bool foreachFuncCtlMask(Source, Func);
};

Type *
SPRVToLLVM::getTranslatedType(SPRVType *BV){
  auto Loc = TypeMap.find(BV);
  if (Loc != TypeMap.end())
    return Loc->second;
  return nullptr;
}

Value *
SPRVToLLVM::getTranslatedValue(SPRVValue *BV){
  auto Loc = ValueMap.find(BV);
  if (Loc != ValueMap.end())
    return Loc->second;
  return nullptr;
}

void
SPRVToLLVM::setAttrByCalledFunc(CallInst *Call) {
  Function *F = Call->getCalledFunction();
  if (F->isIntrinsic()) {
    return;
  }
  Call->setCallingConv(F->getCallingConv());
  Call->setAttributes(F->getAttributes());
}

bool
SPRVToLLVM::transOCLBuiltinsFromVariables(){
  std::vector<GlobalVariable *> WorkList;
  for (auto I = M->global_begin(), E = M->global_end(); I != E; ++I) {
    SPRVBuiltinVariableKind Kind = SPRVBI_Count;
    if (!isSPRVBuiltinVariable(I, &Kind))
      continue;
    if (!transOCLBuiltinFromVariable(I, Kind))
      return false;
    WorkList.push_back(I);
  }
  for (auto &I:WorkList) {
    I->dropAllReferences();
    I->removeFromParent();
  }
  return true;
}

// For integer types shorter than 32 bit, unsigned/signedness can be inferred
// from zext/sext attribute.
MDString *
SPRVToLLVM::transOCLKernelArgTypeName(SPRVFunctionParameter *Arg) {
  auto Ty = Arg->isByVal() ? Arg->getType()->getPointerElementType() :
    Arg->getType();
  return MDString::get(*Context, transTypeToOCLTypeName(Ty, !Arg->isZext()));
}

// Variable like GlobalInvolcationId[x] -> get_global_id(x).
// Variable like WorkDim -> get_work_dim().
bool
SPRVToLLVM::transOCLBuiltinFromVariable(GlobalVariable *GV,
    SPRVBuiltinVariableKind Kind) {
  std::string FuncName = SPIRSPRVBuiltinVariableMap::rmap(Kind);
  std::string MangledName;
  Type *ReturnTy =  GV->getType()->getPointerElementType();
  bool IsVec = ReturnTy->isVectorTy();
  if (IsVec)
    ReturnTy = cast<VectorType>(ReturnTy)->getElementType();
  std::vector<Type*> ArgTy;
  if (IsVec)
    ArgTy.push_back(Type::getInt32Ty(*Context));
  mangle(SPRVBIS_OpenCL20, FuncName, ArgTy, MangledName);
  Function *Func = M->getFunction(MangledName);
  if (!Func) {
    FunctionType *FT = FunctionType::get(ReturnTy, ArgTy, false);
    Func = Function::Create(FT, GlobalValue::ExternalLinkage, MangledName, M);
    Func->setCallingConv(CallingConv::SPIR_FUNC);
    Func->addFnAttr(Attribute::NoUnwind);
    Func->addFnAttr(Attribute::ReadNone);
  }
  std::vector<Instruction *> Deletes;
  std::vector<Instruction *> Uses;
#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
  for (auto UI = GV->user_begin(), UE = GV->user_end(); UI != UE; ++UI) {
#else
  for (auto UI = GV->use_begin(), UE = GV->use_end(); UI != UE; ++UI) {
#endif
    assert (isa<LoadInst>(*UI) && "Unsupported use");
    auto LD = dyn_cast<LoadInst>(*UI);
    if (!IsVec) {
      Uses.push_back(LD);
      Deletes.push_back(LD);
      continue;
    }
#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
    for (auto LDUI = LD->user_begin(), LDUE = LD->user_end(); LDUI != LDUE;
#else
    for (auto LDUI = LD->use_begin(), LDUE = LD->use_end(); LDUI != LDUE;
#endif
        ++LDUI) {
      assert(isa<ExtractElementInst>(*LDUI) && "Unsupported use");
      auto EEI = dyn_cast<ExtractElementInst>(*LDUI);
      Uses.push_back(EEI);
      Deletes.push_back(EEI);
    }
    Deletes.push_back(LD);
  }
  for (auto &I:Uses) {
    std::vector<Value *> Arg;
    if (auto EEI = dyn_cast<ExtractElementInst>(I))
      Arg.push_back(EEI->getIndexOperand());
    auto Call = CallInst::Create(Func, Arg, "", I);
    Call->takeName(I);
    setAttrByCalledFunc(Call);
    SPRVDBG(dbgs() << "[transOCLBuiltinFromVariable] " << *I << " -> " <<
        *Call << '\n';)
    I->replaceAllUsesWith(Call);
  }
  for (auto &I:Deletes) {
    I->dropAllReferences();
    I->removeFromParent();
  }
  return true;
}

Type *
SPRVToLLVM::transFPType(SPRVType* T) {
  switch(T->getFloatBitWidth()) {
  case 16: return Type::getHalfTy(*Context);
  case 32: return Type::getFloatTy(*Context);
  case 64: return Type::getDoubleTy(*Context);
  default:
    assert(0 && "Invalid type");
    return nullptr;
  }
}

std::string SPRVToLLVM::transOCLImageTypeName(SPRV::SPRVTypeSampler* ST) {
  auto Name = SPIRSPRVImageSamplerTypeMap::rmap(ST->getDescriptor());
#if TARGET_LLVM_IMAGE_TYPE_ENCODE_ACCESS_QUAL
  Name = Name + SPIR_TYPE_NAME_DELIMITER +
      SPIRSPRVAccessQualifierMap::rmap(ST->getAccessQualifier());
#endif
  return Name;
}

Type *
SPRVToLLVM::transType(SPRVType *T) {
  auto Loc = TypeMap.find(T);
  if (Loc != TypeMap.end())
    return Loc->second;

  SPRVDBG(bildbgs() << "[transType] " << *T << " -> ";)
  T->validate();
  switch(T->getOpCode()) {
  case SPRVOC_OpTypeVoid:
    return mapType(T, Type::getVoidTy(*Context));
  case SPRVOC_OpTypeBool:
    return mapType(T, Type::getInt1Ty(*Context));
  case SPRVOC_OpTypeInt:
    return mapType(T, Type::getIntNTy(*Context, T->getIntegerBitWidth()));
  case SPRVOC_OpTypeFloat:
    return mapType(T, transFPType(T));
  case SPRVOC_OpTypeArray:
    return mapType(T, ArrayType::get(transType(T->getArrayElementType()),
        T->getArrayLength()));
  case SPRVOC_OpTypePointer:
    return mapType(T, PointerType::get(transType(T->getPointerElementType()),
        SPIRSPRVAddrSpaceMap::rmap(T->getPointerStorageClass())));
  case SPRVOC_OpTypeVector:
    return mapType(T, VectorType::get(transType(T->getVectorComponentType()),
        T->getVectorComponentCount()));
  case SPRVOC_OpTypeOpaque:
    return mapType(T, StructType::create(*Context, T->getName()));
  case SPRVOC_OpTypeFunction: {
    auto FT = static_cast<SPRVTypeFunction *>(T);
    auto RT = transType(FT->getReturnType());
    std::vector<Type *> PT;
    for (size_t I = 0, E = FT->getNumParameters(); I != E; ++I)
      PT.push_back(transType(FT->getParameterType(I)));
    return mapType(T, FunctionType::get(RT, PT, false));
    }
  case SPRVOC_OpTypeSampler: {
    auto ST = static_cast<SPRVTypeSampler *>(T);
    if (ST->IsOCLImage())
      return mapType(T, getOrCreateOpaquePtrType(M,
          transOCLImageTypeName(ST)));
    else if (ST->IsOCLSampler())
      return mapType(T, Type::getInt32Ty(*Context));
    else
      assert(0 && "Unsupported sampler type");
    return nullptr;
  }
  case SPRVOC_OpTypeStruct: {
    auto ST = static_cast<SPRVTypeStruct *>(T);
    std::vector<Type *> MT;
    for (size_t I = 0, E = ST->getMemberCount(); I != E; ++I)
      MT.push_back(transType(ST->getMemberType(I)));
    return mapType(T, StructType::create(*Context, MT, ST->getName(),
      ST->isPacked()));
    } 
  case SPRVOC_OpTypePipe: {
    auto PT = static_cast<SPRVTypePipe *>(T);
    std::vector<Type *> MT;
    MT.push_back(transType(PT->getPipeType()));
    return mapType(T, PointerType::get(StructType::create(*Context, MT,
        "opencl.pipe_t"), SPIRAS_Global));
    }
  default: {
    if (isOpaqueGenericTypeOpCode(T->getOpCode())) {
      return mapType(T, PointerType::get(
          llvm::StructType::create(*Context,
              BuiltinOpaqueGenericTypeOpCodeMap::rmap(T->getOpCode())),
          SPIRAS_Private));
    }
    assert(0 && "Not implemented");
    }
  }
  return 0;
}

std::string
SPRVToLLVM::transTypeToOCLTypeName(SPRVType *T, bool IsSigned) {
  switch(T->getOpCode()) {
  case SPRVOC_OpTypeVoid:
    return "void";
  case SPRVOC_OpTypeBool:
    return "bool";
  case SPRVOC_OpTypeInt: {
    std::string Prefix = IsSigned ? "" : "u";
    switch(T->getIntegerBitWidth()) {
    case 8:
      return Prefix + "char";
    case 16:
      return Prefix + "short";
    case 32:
      return Prefix + "int";
    case 64:
      return Prefix + "long";
    default:
      assert(0 && "invalid integer size");
      return Prefix + std::string("int") + T->getIntegerBitWidth() + "_t";
    }
  }
  break;
  case SPRVOC_OpTypeFloat:
    switch(T->getFloatBitWidth()){
    case 16:
      return "half";
    case 32:
      return "float";
    case 64:
      return "double";
    default:
      assert(0 && "invalid floating pointer bitwidth");
      unsigned size = T->getFloatBitWidth();
      return std::string("float") + T->getFloatBitWidth() + "_t";
    }
    break;
  case SPRVOC_OpTypeArray:
    return "array";
  case SPRVOC_OpTypePointer:
    return transTypeToOCLTypeName(T->getPointerElementType()) + "*";
  case SPRVOC_OpTypeVector:
    return transTypeToOCLTypeName(T->getVectorComponentType()) +
        T->getVectorComponentCount();
  case SPRVOC_OpTypeOpaque:
      return T->getName();
  case SPRVOC_OpTypeFunction:
    assert(0 && "Unsupported");
    return "function";
  case SPRVOC_OpTypeStruct: {
    auto Name = T->getName();
    if (Name.find("struct.") == 0)
      Name[6] = ' ';
    else if (Name.find("union.") == 0)
      Name[5] = ' ';
    return Name;
  }
  case SPRVOC_OpTypePipe:
    return "pipe_t";
  case SPRVOC_OpTypeSampler:
    return SPIRSPRVImageSamplerTypeMap::rmap(static_cast<SPRVTypeSampler *>(T)
        ->getDescriptor()).substr(7);
  default:
      if (isOpaqueGenericTypeOpCode(T->getOpCode())) {
        return BuiltinOpaqueGenericTypeOpCodeMap::rmap(T->getOpCode());
      }
      assert(0 && "Not implemented");
      return "unknown";
  }
}

std::vector<Type *>
SPRVToLLVM::transTypeVector(const std::vector<SPRVType *> &BT) {
  std::vector<Type *> T;
  for (auto I: BT)
    T.push_back(transType(I));
  return T;
}

std::vector<Value *>
SPRVToLLVM::transValue(const std::vector<SPRVValue *> &BV, Function *F,
    BasicBlock *BB) {
  std::vector<Value *> V;
  for (auto I: BV)
    V.push_back(transValue(I, F, BB));
  return V;
}

bool
SPRVToLLVM::isSPRVCmpInstTransToLLVMInst(SPRVInstruction* BI) const {
  auto OC = BI->getOpCode();
  return isCmpOpCode(OC) &&
      !(OC >= SPRVOC_OpLessOrGreater && OC <= SPRVOC_OpUnordered);
}

void
SPRVToLLVM::transFlags(llvm::Value* V) {
  if(!isa<Instruction>(V))
    return;
  auto OC = cast<Instruction>(V)->getOpcode();
  if (OC == Instruction::AShr || OC == Instruction::LShr) {
    cast<BinaryOperator>(V)->setIsExact();
    return;
  }
}

Value *
SPRVToLLVM::transValue(SPRVValue *BV, Function *F, BasicBlock *BB,
    bool CreatePlaceHolder){
  SPRVToLLVMValueMap::iterator Loc = ValueMap.find(BV);
  if (Loc != ValueMap.end() && (!PlaceholderMap.count(BV) || CreatePlaceHolder))
    return Loc->second;

  SPRVDBG(bildbgs() << "[transValue] " << *BV << " -> ";)
  BV->validate();

  auto V = transValueWithoutDecoration(BV, F, BB, CreatePlaceHolder);
  if (!V) {
    SPRVDBG(dbgs() << " Warning ! nullptr\n";)
    return nullptr;
  }
  V->setName(BV->getName());
  if (!transDecoration(BV, V)) {
    assert (0 && "trans decoration fail");
    return nullptr;
  }
  transFlags(V);

  SPRVDBG(dbgs() << *V << '\n';)

  return V;
}

Value *
SPRVToLLVM::transConvertInst(SPRVValue* BV, Function* F, BasicBlock* BB) {
  SPRVUnary* BC = static_cast<SPRVUnary*>(BV);
  auto Src = transValue(BC->getOperand(), F, BB, BB ? true : false);
  auto Dst = transType(BC->getType());
  CastInst::CastOps CO = Instruction::BitCast;
  bool IsExt = Dst->getScalarSizeInBits()
      > Src->getType()->getScalarSizeInBits();
  switch (BC->getOpCode()) {
  case SPRVOC_OpPtrCastToGeneric:
  case SPRVOC_OpGenericCastToPtr:
    CO = Instruction::AddrSpaceCast;
    break;
  case SPRVOC_OpSConvert:
    CO = IsExt ? Instruction::SExt : Instruction::Trunc;
    break;
  case SPRVOC_OpUConvert:
    CO = IsExt ? Instruction::ZExt : Instruction::Trunc;
    break;
  case SPRVOC_OpFConvert:
    CO = IsExt ? Instruction::FPExt : Instruction::FPTrunc;
    break;
  default:
    CO = static_cast<CastInst::CastOps>(OpCodeMap::rmap(BC->getOpCode()));
  }
  assert(CastInst::isCast(CO) && "Invalid cast op code");
  SPRVDBG(if (!CastInst::castIsValid(CO, Src, Dst)) {
    bildbgs() << "Invalid cast: " << *BV << " -> ";
    dbgs() << "Op = " << CO << ", Src = " << *Src << " Dst = " << *Dst << '\n';
  })
  if (BB)
    return CastInst::Create(CO, Src, Dst, BV->getName(), BB);
  return ConstantExpr::getCast(CO, dyn_cast<Constant>(Src), Dst);
}

BinaryOperator *SPRVToLLVM::transShiftLogicalBitwiseInst(SPRVValue* BV,
    BasicBlock* BB,Function* F) {
  SPRVBinary* BBN = static_cast<SPRVBinary*>(BV);
  assert(BB && "Invalid BB");
  unsigned ThellvmOpCode;
  SPRVOpCode TheBilOpCode = BBN->getOpCode();
  switch (TheBilOpCode) {
  case SPRVOC_OpBitwiseOr:
  case SPRVOC_OpLogicalOr:
    ThellvmOpCode = Instruction::Or;
    break;
  case SPRVOC_OpBitwiseAnd:
  case SPRVOC_OpLogicalAnd:
    ThellvmOpCode = Instruction::And;
    break;
  case SPRVOC_OpBitwiseXor:
  case SPRVOC_OpLogicalXor:
    ThellvmOpCode = Instruction::Xor;
    break;
  default:
    ThellvmOpCode = OpCodeMap::rmap(BBN->getOpCode());
  }
  Instruction::BinaryOps BO = static_cast<Instruction::BinaryOps>(ThellvmOpCode);
  auto Inst = BinaryOperator::Create(BO, transValue(BBN->getOperand(0), F, BB),
      transValue(BBN->getOperand(1), F, BB), BV->getName(), BB);
  return Inst;
}

Instruction *
SPRVToLLVM::transCmpInst(SPRVValue* BV, BasicBlock* BB, Function* F) {
  SPRVCompare* BC = static_cast<SPRVCompare*>(BV);
  assert(BB && "Invalid BB");
  SPRVType* BT = BC->getOperand(0)->getType();
  Instruction* Inst = nullptr;
  if (BT->isTypeVectorOrScalarInt() || BT->isTypePointer())
    Inst = new ICmpInst(*BB, CmpMap::rmap(BC->getOpCode()),
        transValue(BC->getOperand(0), F, BB),
        transValue(BC->getOperand(1), F, BB));
  else if (BT->isTypeVectorOrScalarFloat())
    Inst = new FCmpInst(*BB, CmpMap::rmap(BC->getOpCode()),
        transValue(BC->getOperand(0), F, BB),
        transValue(BC->getOperand(1), F, BB));
  assert(Inst && "not implemented");
  return Inst;
}

Value *
SPRVToLLVM::oclTransConstantSampler(SPRV::SPRVConstantSampler* BCS) {
  auto Lit = (BCS->getAddrMode() << 1) |
      BCS->getNormalized() |
      ((BCS->getFilterMode() + 1) << 4);
  auto Ty = IntegerType::getInt32Ty(*Context);
  return ConstantInt::get(Ty, Lit);
}

// For instructions, this function assumes they are created in order and appended
// to the given basic block. An instruction may use a instruction from another BB which
// has not been translated. Such instructions should be translated to place
// holders at the point of first use, then replaced by real instructions
// when they are created.
//
// When CreatePlaceHolder is true, create a load instruction of a global variable
// as placeholder for SPIRV instruction. Otherwise, create instruction and
// replace placeholder if there is one.
Value *
SPRVToLLVM::transValueWithoutDecoration(SPRVValue *BV, Function *F, BasicBlock *BB,
    bool CreatePlaceHolder){
  // Translation of non-instruction values
  switch(BV->getOpCode()) {
  case SPRVOC_OpConstant: {
    SPRVConstant *BConst = static_cast<SPRVConstant *>(BV);
    SPRVType *BT = BV->getType();
    Type *LT = transType(BT);
    switch(BT->getOpCode()) {
    case SPRVOC_OpTypeBool:
    case SPRVOC_OpTypeInt:
      return mapValue(BV, ConstantInt::get(LT, BConst->getZExtIntValue(),
          static_cast<SPRVTypeInt*>(BT)->isSigned()));
    case SPRVOC_OpTypeFloat: {
      struct llvm::fltSemantics;
      const llvm::fltSemantics *FS = nullptr;
      switch (BT->getFloatBitWidth()) {
      case 16:
        FS = &APFloat::IEEEhalf;
        break;
      case 32:
        FS = &APFloat::IEEEsingle;
        break;
      case 64:
        FS = &APFloat::IEEEdouble;
        break;
      default:
        assert (0 && "invalid float type");
      }
      return mapValue(BV, ConstantFP::get(*Context, APFloat(*FS,
          APInt(BT->getFloatBitWidth(), BConst->getZExtIntValue()))));
    }
    default:
      assert(0 && "Not implemented");
      return NULL;
    }
  }
  break;

  case SPRVOC_OpConstantTrue:
    return mapValue(BV, ConstantInt::getTrue(*Context));

  case SPRVOC_OpConstantFalse:
    return mapValue(BV, ConstantInt::getFalse(*Context));

  case SPRVOC_OpConstantNull: {
    auto LT = transType(BV->getType());
    if (auto PT = dyn_cast<PointerType>(LT))
      return mapValue(BV, ConstantPointerNull::get(PT));
    return mapValue(BV, ConstantAggregateZero::get(LT));
  }

  case SPRVOC_OpConstantComposite: {
    auto BCC = static_cast<SPRVConstantComposite*>(BV);
    std::vector<Constant *> CV;
    for (auto &I:BCC->getElements())
      CV.push_back(dyn_cast<Constant>(transValue(I, F, BB)));
    switch(BV->getType()->getOpCode()) {
    case SPRVOC_OpTypeVector:
      return mapValue(BV, ConstantVector::get(CV));
    case SPRVOC_OpTypeArray:
      return mapValue(BV, ConstantArray::get(
          dyn_cast<ArrayType>(transType(BCC->getType())), CV));
    default:
      assert(0 && "not implemented");
      return nullptr;
    }
  }
  break;

  case SPRVOC_OpConstantSampler: {
    auto BCS = static_cast<SPRVConstantSampler*>(BV);
    return mapValue(BV, oclTransConstantSampler(BCS));
  }

  case SPRVOC_OpUndef:
    return mapValue(BV, UndefValue::get(transType(BV->getType())));

  case SPRVOC_OpVariable: {
    auto BVar = static_cast<SPRVVariable *>(BV);
    auto Initializer = BVar->getInitializer();
    SPRVStorageClassKind BS = BVar->getStorageClass();
    auto Ty = transType(BVar->getType()->getPointerElementType());

    if (BS == SPRVSC_Function) {
        assert (BB && "Invalid BB");
        return mapValue(BV, new AllocaInst(Ty, BV->getName(), BB));
    }
    auto AddrSpace = SPIRSPRVAddrSpaceMap::rmap(BS);
    bool IsConst = BVar->isConstant();
    auto LVar = new GlobalVariable(*M, Ty, IsConst,
        SPIRSPRVLinkageTypeMap::rmap(BVar->getLinkageType()),
        Initializer?dyn_cast<Constant>(transValue(Initializer, F, BB, false)):
            nullptr,
        BV->getName(), 0, GlobalVariable::NotThreadLocal, AddrSpace);
    LVar->setUnnamedAddr(IsConst && Ty->isArrayTy() &&
        Ty->getArrayElementType()->isIntegerTy(8));
    SPRVBuiltinVariableKind BVKind = SPRVBI_Count;
    if (BVar->isBuiltin(&BVKind))
      BuiltinGVMap[LVar] = BVKind;
    return mapValue(BV, LVar);
  }
  break;

  case SPRVOC_OpVariableArray: {
    auto BVA = static_cast<SPRVVariableArray*>(BV);
    assert(BVA->getStorageClass() == SPRVSC_Function && "Invalid Storage Class");
    return mapValue(BV, new AllocaInst(transType(
      BVA->getType()->getPointerElementType()),
      llvm::ConstantInt::get(llvm::Type::getInt64Ty(
      *Context), BVA->getArraySize()),
      BVA->getName(), BB));
  }
  break;

  case SPRVOC_OpFunctionParameter: {
    auto BA = static_cast<SPRVFunctionParameter*>(BV);
    assert (F && "Invalid function");
    unsigned ArgNo = 0;
    for (Function::arg_iterator I = F->arg_begin(), E = F->arg_end(); I != E;
        ++I, ++ArgNo) {
      if (ArgNo == BA->getArgNo())
        return mapValue(BV, I);
    }
    assert (0 && "Invalid argument");
    return NULL;
  }
  break;

  case SPRVOC_OpLabel:
    return mapValue(BV, BasicBlock::Create(*Context, BV->getName(), F));
    break;
  default:
    // do nothing
    break;
  }

  // Creation of place holder
  if (CreatePlaceHolder) {
    auto GV = new GlobalVariable(*M,
        transType(BV->getType()),
        false,
        GlobalValue::PrivateLinkage,
        nullptr,
        std::string(kPlaceholderPrefix) + BV->getName(),
        0, GlobalVariable::NotThreadLocal, 0);
    auto LD = new LoadInst(GV, BV->getName(), BB);
    PlaceholderMap[BV] = LD;
    return mapValue(BV, LD);
  }

  // Translation of instructions
  switch (BV->getOpCode()) {
  case SPRVOC_OpBranch: {
    auto BR = static_cast<SPRVBranch *>(BV);
    assert(BB && "Invalid BB");
    return mapValue(BV, BranchInst::Create(
      dyn_cast<BasicBlock>(transValue(BR->getTargetLabel(), F, BB)), BB));
    }
    break;

  case SPRVOC_OpBranchConditional: {
    auto BR = static_cast<SPRVBranchConditional *>(BV);
    assert(BB && "Invalid BB");
    return mapValue(BV, BranchInst::Create(
      dyn_cast<BasicBlock>(transValue(BR->getTrueLabel(), F, BB)),
      dyn_cast<BasicBlock>(transValue(BR->getFalseLabel(), F, BB)),
      transValue(BR->getCondition(), F, BB),
      BB));
    }
    break;

  case SPRVOC_OpPhi: {
    auto Phi = static_cast<SPRVPhi *>(BV);
    assert(BB && "Invalid BB");
    auto LPhi = dyn_cast<PHINode>(mapValue(BV, PHINode::Create(
      transType(Phi->getType()),
      Phi->getPairs().size() / 2,
      Phi->getName(),
      BB)));
    Phi->foreachPair([&](SPRVValue *IncomingV, SPRVBasicBlock *IncomingBB,
      size_t Index){
      auto Translated = transValue(IncomingV, F, BB);
      LPhi->addIncoming(Translated,
        dyn_cast<BasicBlock>(transValue(IncomingBB, F, BB)));
    });
    return LPhi;
    }
    break;

  case SPRVOC_OpReturn:
    assert(BB && "Invalid BB");
    return mapValue(BV, ReturnInst::Create(*Context, BB));
    break;

  case SPRVOC_OpReturnValue: {
    auto RV = static_cast<SPRVReturnValue *>(BV);
    return mapValue(BV, ReturnInst::Create(*Context,
      transValue(RV->getReturnValue(), F, BB), BB));
    }
    break;

  case SPRVOC_OpStore: {
    SPRVStore *BS = static_cast<SPRVStore*>(BV);
    assert(BB && "Invalid BB");
    return mapValue(BV, new StoreInst(
      transValue(BS->getSrc(), F, BB),
      transValue(BS->getDst(), F, BB),
      BS->SPRVMemoryAccess::isVolatile(),
      BS->SPRVMemoryAccess::getAlignment(),
      BB));
    }
    break;

  case SPRVOC_OpLoad: {
    SPRVLoad *BL = static_cast<SPRVLoad*>(BV);
    assert(BB && "Invalid BB");
    return mapValue(BV, new LoadInst(
      transValue(BL->getSrc(), F, BB),
      BV->getName(),
      BL->SPRVMemoryAccess::isVolatile(),
      BL->SPRVMemoryAccess::getAlignment(),
      BB));
    }
    break;

  case SPRVOC_OpCopyMemorySized: {
    SPRVCopyMemorySized *BC = static_cast<SPRVCopyMemorySized *>(BV);
    assert(BB && "Invalid BB");
    std::string FuncName = "llvm.memcpy";
    SPRVType* BS = BC->getSource()->getType();
    SPRVType* BT = BC->getTarget()->getType();
    Type *Int1Ty = Type::getInt1Ty(*Context);
    Type* Int32Ty = Type::getInt32Ty(*Context);
    Type* VoidTy = Type::getVoidTy(*Context);
    Type* SrcTy = transType(BS);
    Type* TrgTy = transType(BT);
    Type* SizeTy = transType(BC->getSize()->getType());
    Type* ArgTy[] = { TrgTy, SrcTy, SizeTy, Int32Ty, Int1Ty };

    if (BT->getPointerStorageClass() == SPRVSC_Private)
      FuncName += ".p0i8";
    else
      FuncName += ".p1i8";
    if (BS->getPointerStorageClass() == SPRVSC_Private)
      FuncName += ".p0i8";
    else
      FuncName += ".p1i8";
    if (BC->getSize()->getType()->getBitWidth() == 32)
      FuncName += ".i32";
    else
      FuncName += ".i64";

    FunctionType *FT = FunctionType::get(VoidTy, ArgTy, false);
    Function *Func = Function::Create(FT, GlobalValue::ExternalLinkage, FuncName, M);

    if (isFuncNoUnwind())
      Func->addFnAttr(Attribute::NoUnwind);

    Value *Arg[] = { transValue(BC->getTarget(), Func, BB),
                     transValue(BC->getSource(), Func, BB),
                     dyn_cast<llvm::ConstantInt>(transValue(BC->getSize(), Func, BB)),
                     ConstantInt::get(Int32Ty, BC->SPRVMemoryAccess::getAlignment()),
                     ConstantInt::get(Int1Ty, BC->SPRVMemoryAccess::isVolatile())};
    return mapValue( BV, CallInst::Create(Func, Arg, "", BB));
  }
  break;
  case SPRVOC_OpSelect: {
    SPRVSelect *BS = static_cast<SPRVSelect*>(BV);
    assert(BB && "Invalid BB");
    return mapValue(BV, SelectInst::Create(
      transValue(BS->getCondition(), F, BB),
      transValue(BS->getTrueValue(), F, BB),
      transValue(BS->getFalseValue(), F, BB),
      BV->getName(), BB));
    }
    break;

  case SPRVOC_OpSwitch: {
    auto BS = static_cast<SPRVSwitch *>(BV);
    assert(BB && "Invalid BB");
    auto Select = transValue(BS->getSelect(), F, BB);
    auto LS = SwitchInst::Create(Select,
      dyn_cast<BasicBlock>(transValue(BS->getDefault(), F, BB)),
      BS->getNumPairs(), BB);
    BS->foreachPair([&](SPRVWord Literal, SPRVBasicBlock *Label, size_t Index){
      LS->addCase(ConstantInt::get(dyn_cast<IntegerType>(Select->getType()),
        Literal), dyn_cast<BasicBlock>(transValue(Label, F, BB)));
    });
    return mapValue(BV, LS);
    }
    break;

  case SPRVOC_OpAccessChain:
  case SPRVOC_OpInBoundsAccessChain: {
    SPRVAccessChain *AC = static_cast<SPRVAccessChain *>(BV);
    auto Base = transValue(AC->getBase(), F, BB);
    auto Index = transValue(AC->getIndices(), F, BB);
    auto IsInbound = BV->getOpCode() == SPRVOC_OpInBoundsAccessChain;
    Value *V = nullptr;
    if (BB) {
      auto GEP = GetElementPtrInst::Create(Base, Index, BV->getName(), BB);
      GEP->setIsInBounds(IsInbound);
      V = GEP;
    } else {
      V = ConstantExpr::getGetElementPtr(dyn_cast<Constant>(Base), Index,
          IsInbound);
    }
    return mapValue(BV, V);
    }
    break;

  case SPRVOC_OpCompositeExtract: {
    SPRVCompositeExtract *CE = static_cast<SPRVCompositeExtract *>(BV);
    assert(BB && "Invalid BB");
    assert(CE->getComposite()->getType()->isTypeVector() && "Invalid type");
    assert(CE->getIndices().size() == 1 && "Invalid index");
    return mapValue(BV, ExtractElementInst::Create(
      transValue(CE->getComposite(), F, BB),
      ConstantInt::get(*Context, APInt(32, CE->getIndices()[0])),
      BV->getName(), BB));
    }
    break;

  case SPRVOC_OpVectorExtractDynamic: {
    auto CE = static_cast<SPRVVectorExtractDynamic *>(BV);
    assert(BB && "Invalid BB");
    return mapValue(BV, ExtractElementInst::Create(
      transValue(CE->getVector(), F, BB),
      transValue(CE->getIndex(), F, BB),
      BV->getName(), BB));
    }
    break;

  case SPRVOC_OpCompositeInsert: {
    auto CI = static_cast<SPRVCompositeInsert *>(BV);
    assert(BB && "Invalid BB");
    assert(CI->getComposite()->getType()->isTypeVector() && "Invalid type");
    assert(CI->getIndices().size() == 1 && "Invalid index");
    return mapValue(BV, InsertElementInst::Create(
      transValue(CI->getComposite(), F, BB),
      transValue(CI->getObject(), F, BB),
      ConstantInt::get(*Context, APInt(32, CI->getIndices()[0])),
      BV->getName(), BB));
    }
    break;

  case SPRVOC_OpVectorInsertDynamic: {
    auto CI = static_cast<SPRVVectorInsertDynamic *>(BV);
    assert(BB && "Invalid BB");
    return mapValue(BV, InsertElementInst::Create(
      transValue(CI->getVector(), F, BB),
      transValue(CI->getComponent(), F, BB),
      transValue(CI->getIndex(), F, BB),
      BV->getName(), BB));
    }
    break;

    // ToDo: Follow up on https://cvs.khronos.org/bugzilla/show_bug.cgi?id=13427
    // Index -1 is for undef.
  case SPRVOC_OpVectorShuffle: {
    auto VS = static_cast<SPRVVectorShuffle *>(BV);
    assert(BB && "Invalid BB");
    std::vector<Constant *> Components;
    IntegerType *Int32Ty = IntegerType::get(*Context, 32);
    for (auto I : VS->getComponents()) {
      if (I == static_cast<SPRVWord>(-1))
        Components.push_back(UndefValue::get(Int32Ty));
      else
        Components.push_back(ConstantInt::get(Int32Ty, I));
    }
    return mapValue(BV, new ShuffleVectorInst(
      transValue(VS->getVector1(), F, BB),
      transValue(VS->getVector2(), F, BB),
      ConstantVector::get(Components),
      BV->getName(), BB));
    }
    break;

  case SPRVOC_OpFunctionCall: {
    SPRVFunctionCall *BC = static_cast<SPRVFunctionCall *>(BV);
    assert(BB && "Invalid BB");
    auto Call = CallInst::Create(
      transFunction(BC->getFunction()),
      transValue(BC->getArgumentValues(), F, BB),
      BC->getName(),
      BB);
    setCallingConv(Call);
    setAttrByCalledFunc(Call);
    return mapValue(BV, Call);
    }
    break;

  case SPRVOC_OpExtInst:
    return mapValue(BV, transOCLBuiltinFromExtInst(
      static_cast<SPRVExtInst *>(BV), BB));
    break;

  case SPRVOC_OpControlBarrier:
  case SPRVOC_OpMemoryBarrier:
    return mapValue(BV, transOCLBarrierFence(
        static_cast<SPRVInstruction *>(BV), BB));

  case SPRVOC_OpSNegate: {
    SPRVUnary *BC = static_cast<SPRVUnary*>(BV);
    return mapValue(BV, BinaryOperator::CreateNSWNeg(
      transValue(BC->getOperand(), F, BB),
      BV->getName(), BB));
    }

  case SPRVOC_OpFNegate: {
    SPRVUnary *BC = static_cast<SPRVUnary*>(BV);
    return mapValue(BV, BinaryOperator::CreateFNeg(
      transValue(BC->getOperand(), F, BB),
      BV->getName(), BB));
    }
    break;

  case SPRVOC_OpNot: {
    SPRVUnary *BC = static_cast<SPRVUnary*>(BV);
    return mapValue(BV, BinaryOperator::CreateNot(
      transValue(BC->getOperand(), F, BB),
      BV->getName(), BB));
    }
    break;

  default:
  if (BV->isAtomic()) {
    return mapValue(BV, transOCLAtomic(
      static_cast<SPRVAtomicOperatorGeneric *>(BV), BB));
  } else if (isSPRVCmpInstTransToLLVMInst(static_cast<SPRVInstruction*>(BV))) {
    return mapValue(BV, transCmpInst(BV, BB, F));
  } else if (SPIRSPRVBuiltinInstMap::rfind(BV->getOpCode(), nullptr)) {
    return mapValue(BV, transOCLBuiltinFromInst(
        static_cast<SPRVInstruction *>(BV), BB));
  } else if (isBinaryShiftLogicalBitwiseOpCode(BV->getOpCode())) {
        return mapValue(BV, transShiftLogicalBitwiseInst(BV, BB, F));
  } else if (isCvtOpCode(BV->getOpCode())) {
      auto BI = static_cast<SPRVInstruction *>(BV);
      Value *Inst = nullptr;
      if (BI->hasFPRoundingMode() || BI->isSaturatedConversion())
        Inst = transOCLBuiltinFromInst(BI, BB);
      else
        Inst = transConvertInst(BV, F, BB);
      return mapValue(BV, Inst);
  }

  SPRVDBG(bildbgs() << "Cannot translate " << *BV << '\n';)
  assert(0 && "Translation of SPIRV instruction not implemented");
  return NULL;
  }
}

template<class SourceTy, class FuncTy>
bool
SPRVToLLVM::foreachFuncCtlMask(SourceTy Source, FuncTy Func) {
  SPRVWord FCM = Source->getFuncCtlMask();
  SPIRSPRVFuncCtlMaskMap::foreach([&](Attribute::AttrKind Attr,
      SPRVFunctionControlMaskKind Mask){
    if (FCM & Mask)
      Func(Attr);
  });
  return true;
}

Function *
SPRVToLLVM::transFunction(SPRVFunction *BF) {
  auto Loc = FuncMap.find(BF);
  if (Loc != FuncMap.end())
    return Loc->second;

  auto IsKernel = BM->isEntryPoint(SPRVEMDL_Kernel, BF->getId());
  auto Linkage = IsKernel ? GlobalValue::ExternalLinkage :
      SPIRSPRVLinkageTypeMap::rmap(BF->getLinkageType());
  FunctionType *FT = dyn_cast<FunctionType>(transType(BF->getFunctionType()));
  Function *F = dyn_cast<Function>(mapValue(BF, Function::Create(FT, Linkage,
      BF->getName(), M)));
  mapFunction(BF, F);
  if (!F->isIntrinsic()) {
    F->setCallingConv(IsKernel ? CallingConv::SPIR_KERNEL :
        CallingConv::SPIR_FUNC);
    if (isFuncNoUnwind())
      F->addFnAttr(Attribute::NoUnwind);
    foreachFuncCtlMask(BF, [&](Attribute::AttrKind Attr){
      F->addFnAttr(Attr);
    });
  }

  for (Function::arg_iterator I = F->arg_begin(), E = F->arg_end(); I != E;
      ++I) {
    auto BA = BF->getArgument(I->getArgNo());
    mapValue(BA, I);
    const std::string &ArgName = BA->getName();
    if (ArgName.empty())
      continue;
    I->setName(ArgName);
    BA->foreachAttr([&](SPRVFuncParamAttrKind Kind){
      if (Kind == SPRVFPA_Const)
        return;
      F->addAttribute(I->getArgNo() + 1, SPIRSPRVFuncParamAttrMap::rmap(Kind));
    });
  }
  BF->foreachReturnValueAttr([&](SPRVFuncParamAttrKind Kind){
    if (Kind == SPRVFPA_Const)
      return;
    F->addAttribute(AttributeSet::ReturnIndex,
        SPIRSPRVFuncParamAttrMap::rmap(Kind));
  });

  // Creating all basic blocks before creating instructions.
  for (size_t I = 0, E = BF->getNumBasicBlock(); I != E; ++I) {
    transValue(BF->getBasicBlock(I), F, nullptr);
  }

  for (size_t I = 0, E = BF->getNumBasicBlock(); I != E; ++I) {
    SPRVBasicBlock *BBB = BF->getBasicBlock(I);
    BasicBlock *BB = dyn_cast<BasicBlock>(transValue(BBB, F, nullptr));
    for (size_t BI = 0, BE = BBB->getNumInst(); BI != BE; ++BI) {
      SPRVInstruction *BInst = BBB->getInst(BI);
      transValue(BInst, F, BB, false);
    }
  }
  return F;
}

// LLVM convert builtin functions is translated to two instructions:
// y = i32 islessgreater(float x, float z) ->
//     y = i32 ZExt(bool LessGreater(float x, float z))
// When translating back, for simplicity, a trunc instruction is inserted
// w = bool LessGreater(float x, float z) ->
//     w = bool Trunc(i32 islessgreater(float x, float z))
// Optimizer should be able to remove the redundant trunc/zext
void
SPRVToLLVM::transOCLBuiltinFromInstPreproc(SPRVInstruction* BI, Type *&RetTy) {
  auto BT = BI->getType();
  if (isCmpOpCode(BI->getOpCode())) {
    if (BT->isTypeBool())
      RetTy = IntegerType::getInt32Ty(*Context);
    else if (BT->isTypeVectorBool())
      RetTy = VectorType::get(IntegerType::getInt32Ty(*Context),
          BT->getVectorComponentCount());
    else
      assert(0 && "invalid compare instruction");
  }
}

Instruction*
SPRVToLLVM::transOCLBuiltinFromInstPostproc(SPRVInstruction* BI,
    Instruction* Inst, BasicBlock* BB) {
  if (isCmpOpCode(BI->getOpCode()) &&
      BI->getType()->isTypeVectorOrScalarBool()) {
    Inst = CastInst::Create(Instruction::Trunc, Inst, transType(BI->getType()),
        "cvt", BB);
  }
  return Inst;
}

Instruction *
SPRVToLLVM::transOCLBuiltinFromInst(const std::string& FuncName,
    SPRVInstruction* BI, BasicBlock* BB) {
  std::string MangledName;
  std::vector<Type*> ArgTys = transTypeVector(BI->getOperandTypes());
  Type* RetTy = transType(BI->getType());
  transOCLBuiltinFromInstPreproc(BI, RetTy);
  mangle(SPRVBIS_OpenCL20, FuncName, ArgTys, MangledName);
  Function* Func = M->getFunction(MangledName);
  if (!Func) {
    FunctionType* FT = FunctionType::get(RetTy, ArgTys, false);
    Func = Function::Create(FT, GlobalValue::ExternalLinkage, MangledName, M);
    Func->setCallingConv(CallingConv::SPIR_FUNC);
    if (isFuncNoUnwind())
      Func->addFnAttr(Attribute::NoUnwind);
  }
  auto Call = CallInst::Create(Func,
      transValue(BI->getOperands(), BB->getParent(), BB), "", BB);
  Call->setName(BI->getName());
  setAttrByCalledFunc(Call);
  SPRVDBG(bildbgs() << "[transInstToBuiltinCall] " << *BI << " -> "; dbgs() <<
      *Call << '\n';)
  Instruction *Inst = Call;
  Inst = transOCLBuiltinFromInstPostproc(BI, Inst, BB);
  return Inst;
}

std::string
SPRVToLLVM::getOCLBuiltinName(SPRVInstruction* BI) {
  auto OC = BI->getOpCode();
  if (isCvtOpCode(OC))
    return getOCLConvertBuiltinName(BI);
  return SPIRSPRVBuiltinInstMap::rmap(OC);
}

Instruction *
SPRVToLLVM::transOCLBuiltinFromInst(SPRVInstruction *BI, BasicBlock *BB) {
  assert(BB && "Invalid BB");
  auto FuncName = getOCLBuiltinName(BI);
  return transOCLBuiltinFromInst(FuncName, BI, BB);
}

// ToDo: Handle errors.
bool
SPRVToLLVM::translate() {
  if (!transAddressingModel())
    return false;

  for (unsigned I = 0, E = BM->getNumVariables(); I != E; ++I) {
    auto BV = BM->getVariable(I);
    if (BV->getStorageClass() != SPRVSC_Function)
      transValue(BV, nullptr, nullptr);
  }

  for (unsigned I = 0, E = BM->getNumFunctions(); I != E; ++I) {
    transFunction(BM->getFunction(I));
  }
  if (!transKernelMetadata())
    return false;
  if (!transFPContractMetadata())
    return false;
  if (!transSourceLanguage())
    return false;
  if (!transSourceExtension())
    return false;
  if (!transCompilerOption())
    return false;
  if (!transOCLBuiltinsFromVariables())
    return false;

  return true;
}

bool
SPRVToLLVM::transAddressingModel() {
  switch (BM->getAddressingModel()) {
  case SPRVAM_Physical64:
    M->setTargetTriple(SPIR_TARGETTRIPLE64);
    M->setDataLayout(SPIR_DATALAYOUT64);
    break;
  case SPRVAM_Physical32:
    M->setTargetTriple(SPIR_TARGETTRIPLE32);
    M->setDataLayout(SPIR_DATALAYOUT32);
    break;
  case SPRVAM_Logical:
    // Do not set target triple and data layout
    break;
  default:
    SPRVCKRT(0, InvalidAddressingModel, "Actual addressing mode is " +
        (unsigned)BM->getAddressingModel());
  }
  return true;
}

bool
SPRVToLLVM::transDecoration(SPRVValue *BV, Value *V) {
  if (!transAlign(BV, V))
    return false;
  return true;
}

// LLVM-SPIR only has module level fp contract control.
// If any kernel needs fp contract off, the module has fp contract off.
bool
SPRVToLLVM::transFPContractMetadata() {
  bool ContractOff = false;
  for (unsigned I = 0, E = BM->getNumFunctions(); I != E; ++I) {
    SPRVFunction *BF = BM->getFunction(I);
    if (!isOpenCLKernel(BF))
      continue;
    if (BF->getExecutionMode(SPRVEM_ContractionOff)) {
      ContractOff = true;
      break;
    }
  }
  if (!ContractOff)
    M->getOrInsertNamedMetadata(SPIR_MD_ENABLE_FP_CONTRACT);
  return true;
}

std::string SPRVToLLVM::transOCLImageTypeAccessQualifier(
    SPRV::SPRVTypeSampler* ST) {
  return SPIRSPRVAccessQualifierMap::rmap(ST->getAccessQualifier());
}

bool
SPRVToLLVM::transKernelMetadata() {
  NamedMDNode *KernelMDs = M->getOrInsertNamedMetadata(SPIR_MD_KERNELS);
  for (unsigned I = 0, E = BM->getNumFunctions(); I != E; ++I) {
    SPRVFunction *BF = BM->getFunction(I);
    Function *F = static_cast<Function *>(getTranslatedValue(BF));
    assert(F && "Invalid translated function");
    if (F->getCallingConv() != CallingConv::SPIR_KERNEL)
      continue;
#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
    std::vector<llvm::Metadata*> KernelMD;
    KernelMD.push_back(ValueAsMetadata::get(F));
#else
    std::vector<llvm::Value*> KernelMD;
    KernelMD.push_back(F);
#endif
    // Generate metadata for kernel_arg_address_spaces
    addOCLKernelArgumentMetadata(Context, KernelMD,
        SPIR_MD_KERNEL_ARG_ADDR_SPACE, BF,
        [=](SPRVFunctionParameter *Arg){
      SPRVType *ArgTy = Arg->getType();
      SPIRAddressSpace AS = SPIRAS_Private;
      if (ArgTy->isTypePointer())
        AS = SPIRSPRVAddrSpaceMap::rmap(ArgTy->getPointerStorageClass());
      else if (ArgTy->isTypeOCLImage() || ArgTy->isTypePipe())
        AS = SPIRAS_Global;
#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
      return ConstantAsMetadata::get(ConstantInt::get(Type::getInt32Ty(*Context), AS));
#else
      return ConstantInt::get(Type::getInt32Ty(*Context), AS);
#endif
    });
    // Generate metadata for kernel_arg_access_qual
    addOCLKernelArgumentMetadata(Context, KernelMD,
        SPIR_MD_KERNEL_ARG_ACCESS_QUAL, BF,
        [=](SPRVFunctionParameter *Arg){
      std::string Qual;
      if (!Arg->getType()->isTypeOCLImage())
        Qual = "none";
      else {
        auto ST = static_cast<SPRVTypeSampler *>(Arg->getType());
        Qual = transOCLImageTypeAccessQualifier(ST);
      }
      return MDString::get(*Context, Qual);
    });
    // Generate metadata for kernel_arg_type
    addOCLKernelArgumentMetadata(Context, KernelMD,
        SPIR_MD_KERNEL_ARG_TYPE, BF,
        [=](SPRVFunctionParameter *Arg){
      return transOCLKernelArgTypeName(Arg);
    });
    // Generate metadata for kernel_arg_type_qual
    addOCLKernelArgumentMetadata(Context, KernelMD,
        SPIR_MD_KERNEL_ARG_TYPE_QUAL, BF,
        [=](SPRVFunctionParameter *Arg){
      std::string Qual;
      if (Arg->hasDecorate(SPRVDEC_Volatile))
        Qual = "volatile";
      Arg->foreachAttr([&](SPRVFuncParamAttrKind Kind){
        Qual += Qual.empty() ? "" : " ";
        switch(Kind){
        case SPRVFPA_NoAlias:
          Qual += "restrict";
          break;
        case SPRVFPA_Const:
          Qual += "const";
          break;
        default:
          // do nothing.
          break;
        }
      });
      return MDString::get(*Context, Qual);
    });
    // Generate metadata for kernel_arg_base_type
    addOCLKernelArgumentMetadata(Context, KernelMD,
        SPIR_MD_KERNEL_ARG_BASE_TYPE, BF,
        [=](SPRVFunctionParameter *Arg){
      return transOCLKernelArgTypeName(Arg);
    });
    // Generate metadata for kernel_arg_name
    if (BM->getCompileFlag().find("-cl-kernel-arg-info") != std::string::npos) {
      bool ArgHasName = true;
      BF->foreachArgument([&](SPRVFunctionParameter *Arg){
        ArgHasName &= !Arg->getName().empty();
      });
      if (ArgHasName)
        addOCLKernelArgumentMetadata(Context, KernelMD,
            SPIR_MD_KERNEL_ARG_NAME, BF,
            [=](SPRVFunctionParameter *Arg){
          return MDString::get(*Context, Arg->getName());
        });
    }
    // Generate metadata for reqd_work_group_size
    if (auto EM = BF->getExecutionMode(SPRVEM_LocalSize)) {
      KernelMD.push_back(getMDNodeStringIntVec(Context,
          SPIR_MD_REQD_WORK_GROUP_SIZE, EM->getLiterals()));
    }
    // Generate metadata for work_group_size_hint
    if (auto EM = BF->getExecutionMode(SPRVEM_LocalSizeHint)) {
      KernelMD.push_back(getMDNodeStringIntVec(Context,
          SPIR_MD_WORK_GROUP_SIZE_HINT, EM->getLiterals()));
    }
    // Generate metadata for vec_type_hint
    if (auto EM = BF->getExecutionMode(SPRVEM_VecTypeHint)) {
#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
      std::vector<Metadata*> ValueVec;
#else
      std::vector<Value*> ValueVec;
#endif
      ValueVec.push_back(MDString::get(*Context, SPIR_MD_VEC_TYPE_HINT));
      Type *VecHintTy = transType(BM->get<SPRVType>(EM->getLiterals()[0]));
#if (LLVM_VERSION_MAJOR == 3 && LLVM_VERSION_MINOR >= 6)
      ValueVec.push_back(ValueAsMetadata::get(UndefValue::get(VecHintTy)));
      ValueVec.push_back(ConstantAsMetadata::get(ConstantInt::get(Type::getInt32Ty(*Context),
          VecHintTy->isIntegerTy() && EM->getStringLiteral()[0] != 'u'?1:0)));
#else
      ValueVec.push_back(UndefValue::get(VecHintTy));
      ValueVec.push_back(ConstantInt::get(Type::getInt32Ty(*Context),
        VecHintTy->isIntegerTy() && EM->getStringLiteral()[0] != 'u' ? 1 : 0));
#endif
      KernelMD.push_back(MDNode::get(*Context, ValueVec));
    }

    llvm::MDNode *Node = MDNode::get(*Context, KernelMD);
    KernelMDs->addOperand(Node);
  }
  return true;
}

bool
SPRVToLLVM::transAlign(SPRVValue *BV, Value *V) {
  if (auto AL = dyn_cast<AllocaInst>(V)) {
    SPRVWord Align = 0;
    if (BV->hasAlignment(&Align))
      AL->setAlignment(Align);
    return true;
  }
  if (auto GV = dyn_cast<GlobalVariable>(V)) {
    SPRVWord Align = 0;
    if (BV->hasAlignment(&Align))
      GV->setAlignment(Align);
    return true;
  }
  return true;
}

Instruction *
SPRVToLLVM::transOCLAtomic(SPRVAtomicOperatorGeneric *BA, BasicBlock *BB) {
  assert(BB && "Invalid BB");
  std::string FuncName = SPIRSPRVBuiltinInstMap::rmap(BA->getOpCode());
  std::string MangledName;
  std::vector<Type *> ArgTys = transTypeVector(BA->getOperandTypes());
  Type * RetTy = ArgTys[0]->getPointerElementType();
  mangle(SPRVBIS_OpenCL20, FuncName, ArgTys, MangledName);
  Function *Func = M->getFunction(MangledName);
  if (!Func) {
    FunctionType *FT = FunctionType::get(RetTy, ArgTys, false);
    Func = Function::Create(FT, GlobalValue::ExternalLinkage, MangledName, M);
    Func->setCallingConv(CallingConv::SPIR_FUNC);
    if (isFuncNoUnwind())
      Func->addFnAttr(Attribute::NoUnwind);
  }
  auto Call = CallInst::Create(Func, transValue(BA->getOperands(),
      BB->getParent(), BB), "", BB);
  Call->setName(BA->getName());
  setAttrByCalledFunc(Call);
  SPRVDBG(bildbgs() << "[transAtomic] " << *BA << " -> ";
    dbgs() << *Call << '\n';)
  return Call;
}

void
SPRVToLLVM::transOCLVectorLoadStore(std::string& UnmangledName,
    std::vector<SPRVWord> &BArgs) {
  if (UnmangledName.find("vload") == 0 &&
      UnmangledName.find("n") != std::string::npos) {
    if (BArgs.back() != 1) {
      std::stringstream SS;
      SS << BArgs.back();
      UnmangledName.replace(UnmangledName.find("n"), 1, SS.str());
    } else {
      UnmangledName.erase(UnmangledName.find("n"), 1);
    }
    BArgs.pop_back();
  } else if (UnmangledName.find("vstore") == 0) {
    if (UnmangledName.find("n") != std::string::npos) {
      auto T = BM->getValueType(BArgs[0]);
      if (T->isTypeVector()) {
        auto W = T->getVectorComponentCount();
        std::stringstream SS;
        SS << W;
        UnmangledName.replace(UnmangledName.find("n"), 1, SS.str());
      } else {
        UnmangledName.erase(UnmangledName.find("n"), 1);
      }
    }
    if (UnmangledName.find("_r") != std::string::npos) {
      UnmangledName.replace(UnmangledName.find("_r"), 2, std::string("_") +
          SPIRSPRVFPRoundingModeMap::rmap(static_cast<SPRVFPRoundingModeKind>(
              BArgs.back())));
      BArgs.pop_back();
    }
   }
}

// printf is not mangled. The function type should have just one argument.
// read_image*: the second argument should be mangled as sampler.
Instruction *
SPRVToLLVM::transOCLBuiltinFromExtInst(SPRVExtInst *BC, BasicBlock *BB) {
  assert(BB && "Invalid BB");
  std::string MangledName;
  SPRVWord EntryPoint = BC->getEntryPoint();
  SPRVExtInstSetKind Set = BM->getBuiltinSet(BC->getBuiltinSet());
  bool IsVarArg = false;
  bool IsPrintf = false;
  std::string UnmangledName;
  auto BArgs = BC->getArguments();

  if (Set == SPRVBIS_OpenCL12) {
    if (EntryPoint == OCL12_Printf)
      IsPrintf = true;
    else {
      UnmangledName = OCL12Map::map(static_cast<SPRVBuiltinOCL12Kind>(
          EntryPoint));
    }
  } else if (Set == SPRVBIS_OpenCL20) {
    if (EntryPoint == OCL20_Printf)
      IsPrintf = true;
    else {
      UnmangledName = OCL20Map::map(static_cast<SPRVBuiltinOCL20Kind>(
          EntryPoint));
    }
  }

  SPRVDBG(bildbgs() << "[transOCLBuiltinFromExtInst] OrigUnmangledName: " <<
      UnmangledName << '\n');
  transOCLVectorLoadStore(UnmangledName, BArgs);

  std::vector<Type *> ArgTypes = transTypeVector(BC->getValueTypes(BArgs));

  if (IsPrintf) {
    MangledName = "printf";
    IsVarArg = true;
    ArgTypes.resize(1);
  } else if (UnmangledName.find("read_image") == 0) {
    auto ModifiedArgTypes = ArgTypes;
    ModifiedArgTypes[1] = getOrCreateOpaquePtrType(M, "opencl.sampler_t");
    mangle(Set, UnmangledName, ModifiedArgTypes, MangledName);
  } else {
    mangle(Set, UnmangledName, ArgTypes, MangledName);
  }
  SPRVDBG(bildbgs() << "[transOCLBuiltinFromExtInst] ModifiedUnmangledName: " <<
      UnmangledName << " MangledName: " << MangledName << '\n');

  FunctionType *FT = FunctionType::get(
      transType(BC->getType()),
      ArgTypes,
      IsVarArg);
  Function *F = M->getFunction(MangledName);
  if (!F) {
    F = Function::Create(FT,
      GlobalValue::ExternalLinkage,
      MangledName,
      M);
    F->setCallingConv(CallingConv::SPIR_FUNC);
    if (isFuncNoUnwind())
      F->addFnAttr(Attribute::NoUnwind);
  }
  auto Args = transValue(BC->getValues(BArgs), F, BB);
  SPRVDBG(dbgs() << "[transOCLBuiltinFromExtInst] Function: " << *F << ", Args: ";
    for (auto &I:Args) dbgs() << *I << ", "; dbgs() << '\n');
  CallInst *Call = CallInst::Create(F,
      Args,
      BC->getName(),
      BB);
  setCallingConv(Call);
  addFnAttr(Context, Call, Attribute::NoUnwind);
  return Call;
}

// OpenCL barrier is always accompanied by mem fence.
// Assumes OpenCL barrier is translated to an OpControlBarrier together with
// an OpMemoryBarrir.
Instruction *
SPRVToLLVM::transOCLBarrierFence(SPRVInstruction* MB, BasicBlock *BB) {
  assert(BB && "Invalid BB");
  std::string FuncName;
  SPRVWord MemSema = 0;
  if (MB->getOpCode() == SPRVOC_OpMemoryBarrier) {
    auto MemB = static_cast<SPRVMemoryBarrier*>(MB);
    FuncName = "mem_fence";
    MemSema = MemB->getMemSemantic();
  } else if (MB->getOpCode() == SPRVOC_OpControlBarrier) {
    auto CtlB = static_cast<SPRVControlBarrier*>(MB);
    FuncName = "barrier";
    MemSema = CtlB->getMemSemantic();
  } else {
    assert(0 && "Invalid instruction");
  }
  std::string MangledName;
  Type* Int32Ty = Type::getInt32Ty(*Context);
  Type* VoidTy = Type::getVoidTy(*Context);
  Type* ArgTy[] = {Int32Ty};
  mangle(SPRVBIS_OpenCL20, FuncName, ArgTy, MangledName);
  Function *Func = M->getFunction(MangledName);
  if (!Func) {
    FunctionType *FT = FunctionType::get(VoidTy, ArgTy, false);
    Func = Function::Create(FT, GlobalValue::ExternalLinkage, MangledName, M);
    Func->setCallingConv(CallingConv::SPIR_FUNC);
    if (isFuncNoUnwind())
      Func->addFnAttr(Attribute::NoUnwind);
  }
  Value *Arg[] = {ConstantInt::get(Int32Ty,
      rmapBitMask<SPIRSPRVMemFenceFlagMap>(MemSema))};
  auto Call = CallInst::Create(Func, Arg, "", BB);
  Call->setName(MB->getName());
  setAttrByCalledFunc(Call);
  SPRVDBG(bildbgs() << "[transBarrier] " << *MB << " -> ";
    dbgs() << *Call << '\n';)
  return Call;
}

// SPIRV only contains language version. Use OpenCL language version as
// SPIR version.
bool
SPRVToLLVM::transSourceLanguage() {
  SPRVWord Ver = 0;
  SPRVSourceLanguageKind Lang = BM->getSourceLanguage(&Ver);
  assert(Lang == SPRVSL_OpenCL && "Unsupported source language");
  unsigned Major = Ver/10;
  unsigned Minor = (Ver%10);
  addOCLVersionMetadata(Context, M, SPIR_MD_SPIR_VERSION, Major, Minor);
  addOCLVersionMetadata(Context, M, SPIR_MD_OCL_VERSION, Major, Minor);
  return true;
}

bool
SPRVToLLVM::transSourceExtension() {
  std::string OCLExtensions = BM->getSourceExtension();
  std::string OCLOptionalCoreFeatures;
  bool First = true;
  static const char *OCLOptCoreFeatureNames[] = {
      "cl_images",
      "cl_doubles",
  };
  for (auto &I:OCLOptCoreFeatureNames) {
    size_t Loc = OCLExtensions.find(I);
    if (Loc != std::string::npos) {
      OCLExtensions.erase(Loc, strlen(I));
      if (First)
        First = false;
      else
        OCLOptionalCoreFeatures += ' ';
      OCLOptionalCoreFeatures += I;
    }
  }
  addNamedMetadataString(Context, M, SPIR_MD_USED_EXTENSIONS, OCLExtensions);
  addNamedMetadataString(Context, M, SPIR_MD_USED_OPTIONAL_CORE_FEATURES,
      OCLOptionalCoreFeatures);
  return true;
}

bool
SPRVToLLVM::transCompilerOption() {
  addNamedMetadataString(Context, M, SPIR_MD_COMPILER_OPTIONS,
      BM->getCompileFlag());
  return true;
}

bool ReadSPRV(LLVMContext &C, std::istream &IS, Module *&M,
    SPRVErrorCode &ErrCode, std::string &ErrMsg) {
  M = new Module("", C);
  std::unique_ptr<SPRVModule> BM(SPRVModule::createSPRVModule());

  IS >> *BM;

  SPRVToLLVM BTL(M, BM.get());
  bool Succeed = true;
  if (!BTL.translate()) {
    ErrCode = BM->getError(ErrMsg);
    Succeed = false;
  }
  if (DbgSaveTmpLLVM)
    dumpLLVM(M, DbgTmpLLVMFileName);
  if (!Succeed) {
    delete M;
    M = nullptr;
  }
  return Succeed;
}

// If the argument is unsigned return uconvert*, otherwise return convert*.
std::string
SPRVToLLVM::getOCLConvertBuiltinName(SPRVInstruction* BI) {
  auto OC = BI->getOpCode();
  assert(isCvtOpCode(OC) && "Not convert instruction");
  auto U = static_cast<SPRVUnary *>(BI);
  std::string Name;
  if (isCvtFromUnsignedOpCode(OC))
    Name = "u";
  Name += "convert_";
  Name += mapSPRVTypeToOpenCLType(U->getType(),
      !isCvtToUnsignedOpCode(OC));
  SPRVFPRoundingModeKind Rounding = SPRVFRM_Count;
  if (U->isSaturatedConversion())
    Name += "_sat";
  if (U->hasFPRoundingMode(&Rounding)) {
    Name += "_";
    Name += SPIRSPRVFPRoundingModeMap::rmap(Rounding);
  }
  return Name;
}

}

