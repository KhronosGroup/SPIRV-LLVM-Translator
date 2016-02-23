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

cat $spirvHeader | sed -n -e "/^ *${prefix}/s:^ *${prefix}\([^= ][^= ]*\)[= ][= ]*\([0x]*[0-9][0-9]*\).*:\1 \2:p"  | while read a b; do
  #printf "_SPIRV_OP(%s, %s)\n" $a $b
  printf "  add(${prefix}%s, \"%s\");\n" $a $a
  #i=$((i+1))
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
echo "bool
isValid(spv::$prefix V) {
  switch(V) {"

cat $spirvHeader | sed -n -e "/^ *${prefix}/s:^ *${prefix}\([^= ][^= ]*\)[= ][= ]*\(.*\).*:\1 \2:p"  | while read a b; do
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

cat $spirvHeader | sed -n -e "/^ *${prefix}/s:^ *${prefix}\([^= ][^= ]*\)[= ][= ]*\([0xX]*[0-9a-fA-F][0-9a-fA-F]*\).*:\1 \2:p"  | while read a b; do
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
  ImageChannelOrder ImageChannelDataType ImageOperands FPFastMathMode FPRoundingMode LinkageType AccessQualifier FunctionParameterAttribute Decoration BuiltIn SelectionControl \
  LoopControl FunctionControl MemorySemantics MemoryAccess Scope GroupOperation KernelEnqueueFlags KernelProfilingInfo Capability Op; do
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

#spirvHeader=/home/yaxunl/stg/compiler/llvm/lib/SPIRV/libSPIRV/spirv.hpp
spirvHeader=$1
type=$2

gen $type
