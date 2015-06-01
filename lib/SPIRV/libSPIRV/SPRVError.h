//===- SPRVError.h - SPIR-V error code and checking -------------*- C++ -*-===//
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
// This file defines SPIRV error code and checking utility.
//
//===----------------------------------------------------------------------===//

#ifndef SPRVERROR_HPP_
#define SPRVERROR_HPP_

#include "SPRVUtil.h"
#include "SPRVDebug.h"
#include <string>
#include <sstream>

namespace SPRV{

// Check condition and set error code and error msg.
// To use this macro, function checkError must be defined in the scope.
#define SPRVCK(Condition,ErrCode,ErrMsg) \
  getErrorLog().checkError(Condition, SPRVEC_##ErrCode, std::string()+ErrMsg,\
      #Condition, __FILE__, __LINE__)

// Check condition and set error code and error msg. If fail returns false.
#define SPRVCKRT(Condition,ErrCode,ErrMsg) \
  if (!getErrorLog().checkError(Condition, SPRVEC_##ErrCode,\
      std::string()+ErrMsg, #Condition, __FILE__, __LINE__))\
    return false;

// Defines error code enum type SPRVErrorCode.
enum SPRVErrorCode {
#define _SPRV_OP(x,y) SPRVEC_##x,
#include "SPRVErrorEnum.h"
#undef _SPRV_OP
};

// Defines OpErorMap which maps error code to a string describing the error.
template<> inline void
SPRVMap<SPRVErrorCode, std::string>::init() {
#define _SPRV_OP(x,y) add(SPRVEC_##x, std::string(#x)+": "+y);
#include "SPRVErrorEnum.h"
#undef _SPRV_OP
}

typedef SPRVMap<SPRVErrorCode, std::string> SPRVErrorMap;

class SPRVErrorLog {
public:
  SPRVErrorLog():ErrorCode(SPRVEC_Success){}
  SPRVErrorCode getError(std::string& ErrMsg) {
    ErrMsg = ErrorMsg;
    return ErrorCode;
  }
  void setError(SPRVErrorCode ErrCode, const std::string& ErrMsg) {
    ErrorCode = ErrCode;
    ErrorMsg = ErrMsg;
  }
  // Check if Condition is satisfied and set ErrCode and DetailedMsg
  // if not. Returns true if no error.
  bool checkError(bool Condition, SPRVErrorCode ErrCode,
      const std::string& DetailedMsg = "",
      const char *CondString = nullptr,
      const char *FileName = nullptr,
      unsigned LineNumber = 0);
protected:
  SPRVErrorCode ErrorCode;
  std::string ErrorMsg;

};

inline bool
SPRVErrorLog::checkError(bool Cond, SPRVErrorCode ErrCode,
    const std::string& Msg, const char *CondString, const char *FileName,
    unsigned LineNo) {
  std::stringstream SS;
  if (Cond)
    return Cond;
  // Do not overwrite previous failure.
  if (ErrorCode != SPRVEC_Success)
    return Cond;
  SS << SPRVErrorMap::map(ErrCode) << " " << Msg;
  if (SPRVDbgErrorMsgIncludesSourceInfo)
    SS <<" [Src: " << FileName << ":" << LineNo << " " << CondString << " ]";
  setError(ErrCode, SS.str());
  if (SPRVDbgAssertOnError) {
    bildbgs() << SS.str() << '\n';
    bildbgs().flush();
    assert (0);
  }
  return Cond;
}

}


#endif /* SPRVERROR_HPP_ */
