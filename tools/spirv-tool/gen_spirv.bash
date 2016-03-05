#!/usr/bin/bash
# script to generate code for LLVM/SPIR-V translator based on khronos 
# header file spirv.hpp.
#


######################
#
# generate NameMap
#
######################

genNameMap() {
prefix=$1
echo "template<> inline void
SPIRVMap<$prefix, std::string>::init() {"

cat $spirvHeader | sed -n -e "/^ *${prefix}[^a-z]/s:^ *${prefix}\([^= ][^= ]*\)[= ][= ]*\([0x]*[0-9][0-9]*\).*:\1 \2:p"  | while read a b; do
  printf "  add(${prefix}%s, \"%s\");\n" $a $a
done

echo "}
SPIRV_DEF_NAMEMAP($prefix, SPIRV${prefix}NameMap)
"

}

###########################
#
# generate isValid function
#
###########################
genIsValid() {
prefix=$1
echo "inline bool
isValid(spv::$prefix V) {
  switch(V) {"

  cat $spirvHeader | sed -n -e "/^ *${prefix}[^a-z]/s:^ *${prefix}\([^= ][^= ]*\)[= ][= ]*\(.*\).*:\1 \2:p"  | while read a b; do
  if [[ $a == CapabilityNone ]]; then
    continue
  fi
  printf "    case ${prefix}%s:\n" $a
done

echo "      return true;
    default:
      return false;
  }
}
"
}
genMaskIsValid() {
prefix=$1
subprefix=`echo $prefix | sed -e "s:Mask::g"`
echo "inline bool
isValid$prefix(SPIRVWord Mask) {
  SPIRVWord ValidMask = 0u;"

  cat $spirvHeader | sed -n -e "/^ *${subprefix}[^a-z]/s:^ *${subprefix}\([^= ][^= ]*\)Mask[= ][= ]*\(.*\).*:\1 \2:p"  | while read a b; do
  if [[ $a == None ]]; then
    continue
  fi
  printf "  ValidMask |= ${subprefix}%sMask;\n" $a
done

echo "
  return (Mask & ~ValidMask) == 0;
}
"
}

##############################
#
# generate entries for td file
#
##############################
genTd() {
prefix=$1

if [[ $prefix == "Capability" ]]; then
  echo "class SPIRV${prefix}_ {"
else
  echo "def SPIRV${prefix} : Operand<i32> {
  let PrintMethod = \"printSPIRV${prefix}\";
"
fi

cat $spirvHeader | sed -n -e "/^ *${prefix}[^a-z]/s:^ *${prefix}\([^= ][^= ]*\)[= ][= ]*\([0xX]*[0-9a-fA-F][0-9a-fA-F]*\).*:\1 \2:p"  | while read a b; do
  if [[ $a == CapabilityNone ]]; then
    continue
  fi
  printf "  int %s = %s;\n" $a $b
done

if [[ $prefix == "Capability" ]]; then
  echo "}
def SPIRV${prefix} : SPIRV${prefix}_;
"
else 
  echo "}
"
fi
}

gen() {
type=$1
for prefix in SourceLanguage ExecutionModel AddressingModel MemoryModel ExecutionMode StorageClass Dim SamplerAddressingMode SamplerFilterMode ImageFormat \
  ImageChannelOrder ImageChannelDataType FPRoundingMode LinkageType AccessQualifier FunctionParameterAttribute Decoration BuiltIn Scope GroupOperation \
  KernelEnqueueFlags Capability Op; do
  if [[ "$type" == NameMap ]]; then
    genNameMap $prefix
  elif [[ "$type" == isValid ]]; then
    genIsValid $prefix
  elif [[ "$type" == td ]]; then
    genTd $prefix
  else
    echo "invalid type \"$type\"."
    exit
  fi
done
for prefix in ImageOperandsMask FPFastMathModeMask SelectionControlMask LoopControlMask FunctionControlMask MemorySemanticsMask MemoryAccessMask \
  KernelProfilingInfoMask; do
  if [[ "$type" == isValid ]]; then
    genMaskIsValid $prefix
  fi
done
}

####################
#
# main
#
####################

if [[ $# -ne 2 ]]; then
  echo "usage: gen_spirv path_to_spirv.hpp [NameMap|isValid|td]"
  exit
fi

spirvHeader=$1
type=$2

gen $type
