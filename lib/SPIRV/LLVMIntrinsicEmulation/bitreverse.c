#include <stdlib.h>
#include <stdint.h>

#define MASK32LO 0x00000000FFFFFFFFLLU
#define MASK16LO 0x0000FFFF0000FFFFLLU
#define  MASK8LO 0x00FF00FF00FF00FFLLU
#define  MASK4LO 0x0F0F0F0F0F0F0F0FLLU
#define  MASK2LO 0x3333333333333333LLU
#define  MASK1LO 0x5555555555555555LLU

#define SWAP32(X,TYPE) (((X&((TYPE) MASK32LO))<<32) | (((X)>>32)&((TYPE) MASK32LO)))
#define SWAP16(X,TYPE) (((X&((TYPE) MASK16LO))<<16) | (((X)>>16)&((TYPE) MASK16LO)))
#define  SWAP8(X,TYPE) (((X&((TYPE) MASK8LO ))<< 8) | (((X)>> 8)&((TYPE) MASK8LO)))
#define  SWAP4(X,TYPE) (((X&((TYPE) MASK4LO ))<< 4) | (((X)>> 4)&((TYPE) MASK4LO)))
#define  SWAP2(X,TYPE) (((X&((TYPE) MASK2LO ))<< 2) | (((X)>> 2)&((TYPE) MASK2LO)))
#define  SWAP1(X,TYPE) (((X&((TYPE) MASK1LO ))<< 1) | (((X)>> 1)&((TYPE) MASK1LO)))

///////////////////////////////////////////////////////////////////////////////////////
// scalar
///////////////////////////////////////////////////////////////////////////////////////

uint8_t llvm_bitreverse_i8(uint8_t a) {
  a=SWAP4(a,uint8_t);    
  a=SWAP2(a,uint8_t);
  a=SWAP1(a,uint8_t);
  return a;
}

uint16_t llvm_bitreverse_i16(uint16_t a) {
  a=SWAP8(a,uint16_t);
  a=SWAP4(a,uint16_t);
  a=SWAP2(a,uint16_t);
  a=SWAP1(a,uint16_t);
  return a;
}

uint32_t llvm_bitreverse_i32(uint32_t a) {
  a=SWAP16(a,uint32_t);  
  a=SWAP8(a,uint32_t);  
  a=SWAP4(a,uint32_t);  
  a=SWAP2(a,uint32_t);  
  a=SWAP1(a,uint32_t);  
  return a;  
}

uint64_t llvm_bitreverse_i64(uint64_t a) {
  a=SWAP32(a,uint64_t);
  a=SWAP16(a,uint64_t);    
  a=SWAP8(a,uint64_t);  
  a=SWAP4(a,uint64_t);  
  a=SWAP2(a,uint64_t);  
  a=SWAP1(a,uint64_t);  
  return a;    
}

///////////////////////////////////////////////////////////////////////////////////////
// 2-element vector 
///////////////////////////////////////////////////////////////////////////////////////

typedef  uint8_t  uint8_t2  __attribute__((ext_vector_type(2)));
typedef uint16_t uint16_t2  __attribute__((ext_vector_type(2)));
typedef uint32_t uint32_t2  __attribute__((ext_vector_type(2)));
typedef uint64_t uint64_t2  __attribute__((ext_vector_type(2)));

uint8_t2 llvm_bitreverse_v2i8(uint8_t2 a) {
  a=SWAP4(a,uint8_t);    
  a=SWAP2(a,uint8_t);
  a=SWAP1(a,uint8_t);
  return a;
}

uint16_t2 llvm_bitreverse_v2i16(uint16_t2 a) {
  a=SWAP8(a,uint16_t);
  a=SWAP4(a,uint16_t);
  a=SWAP2(a,uint16_t);
  a=SWAP1(a,uint16_t);
  return a;
}

uint32_t2 llvm_bitreverse_v2i32(uint32_t2 a) {
  a=SWAP16(a,uint32_t);  
  a=SWAP8(a,uint32_t);  
  a=SWAP4(a,uint32_t);  
  a=SWAP2(a,uint32_t);  
  a=SWAP1(a,uint32_t);  
  return a;  
}

uint64_t2 llvm_bitreverse_v2i64(uint64_t2 a) {
  a=SWAP32(a,uint64_t);
  a=SWAP16(a,uint64_t);    
  a=SWAP8(a,uint64_t);  
  a=SWAP4(a,uint64_t);  
  a=SWAP2(a,uint64_t);  
  a=SWAP1(a,uint64_t);  
  return a;    
}

///////////////////////////////////////////////////////////////////////////////////////
// 4-element vector 
///////////////////////////////////////////////////////////////////////////////////////

typedef  uint8_t  uint8_t4  __attribute__((ext_vector_type(4)));
typedef uint16_t uint16_t4  __attribute__((ext_vector_type(4)));
typedef uint32_t uint32_t4  __attribute__((ext_vector_type(4)));
typedef uint64_t uint64_t4  __attribute__((ext_vector_type(4)));

uint8_t4 llvm_bitreverse_v4i8(uint8_t4 a) {
  a=SWAP4(a,uint8_t);    
  a=SWAP2(a,uint8_t);
  a=SWAP1(a,uint8_t);
  return a;
}

uint16_t4 llvm_bitreverse_v4i16(uint16_t4 a) {
  a=SWAP8(a,uint16_t);
  a=SWAP4(a,uint16_t);
  a=SWAP2(a,uint16_t);
  a=SWAP1(a,uint16_t);
  return a;
}

uint32_t4 llvm_bitreverse_v4i32(uint32_t4 a) {
  a=SWAP16(a,uint32_t);  
  a=SWAP8(a,uint32_t);  
  a=SWAP4(a,uint32_t);  
  a=SWAP2(a,uint32_t);  
  a=SWAP1(a,uint32_t);  
  return a;  
}

uint64_t4 llvm_bitreverse_v4i64(uint64_t4 a) {
  a=SWAP32(a,uint64_t);
  a=SWAP16(a,uint64_t);    
  a=SWAP8(a,uint64_t);  
  a=SWAP4(a,uint64_t);  
  a=SWAP2(a,uint64_t);  
  a=SWAP1(a,uint64_t);  
  return a;    
}
