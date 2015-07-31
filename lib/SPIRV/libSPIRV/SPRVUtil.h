//===- SPRVUtil.h - SPIR-V Utility Functions --------------------*- C++ -*-===//
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
/// \file
///
/// This file defines SPIR-V utility functions.
///
//===----------------------------------------------------------------------===//

#ifndef SPRVUTIL_H_
#define SPRVUTIL_H_

#include <algorithm>
#include <cassert>
#include <functional>
#include <map>
#include <sstream>
#include <string>

namespace SPRV{

#define SPRV_DEF_NAMEMAP(Type,MapType) \
typedef SPRVMap<Type, std::string> MapType; \
inline MapType getNameMap(Type){ MapType MT; return MT;}

// A bi-way map
template<class Ty1, class Ty2, class Identifier = void>
struct SPRVMap {
public:
  typedef Ty1 KeyTy;
  typedef Ty2 ValueTy;
  // Initialize map entries
  virtual void init();
  virtual ~SPRVMap(){}

  static Ty2 map(Ty1 Key) {
    Ty2 Val;
    bool Found = find(Key, &Val);
    assert (Found && "Invalid key");
    return Val;
  }

  static Ty1 rmap(Ty2 Key) {
    Ty1 Val;
    bool Found = rfind(Key, &Val);
    assert (Found && "Invalid key");
    return Val;
  }

  static const SPRVMap& getMap() {
    static const SPRVMap Map(false);
    return Map;
  }

  static const SPRVMap& getRMap() {
    static const SPRVMap Map(true);
    return Map;
  }

  static void foreach(std::function<void(Ty1, Ty2)>F) {
    for (auto &I:getMap().Map)
      F(I.first, I.second);
  }

  // For each key/value in the map executes function \p F.
  // If \p F returns false break the iteration.
  static void foreach_conditional(std::function<bool(const Ty1&, Ty2)>F) {
    for (auto &I:getMap().Map) {
      if (!F(I.first, I.second))
        break;
    }
  }

  static bool find(Ty1 Key, Ty2 *Val = nullptr) {
    const SPRVMap& Map = getMap();
    typename MapTy::const_iterator Loc = Map.Map.find(Key);
    if(Loc == Map.Map.end())
      return false;
    if (Val)
      *Val = Loc->second;
    return true;
  }

  static bool rfind(Ty2 Key, Ty1 *Val = nullptr) {
    const SPRVMap& Map = getRMap();
    typename RevMapTy::const_iterator Loc = Map.RevMap.find(Key);
    if (Loc == Map.RevMap.end())
      return false;
    if (Val)
      *Val = Loc->second;
    return true;
  }
  SPRVMap():IsReverse(false){}
protected:
  SPRVMap(bool Reverse):IsReverse(Reverse){
    init();
  }
  typedef std::map<Ty1, Ty2> MapTy;
  typedef std::map<Ty2, Ty1> RevMapTy;

  virtual void add(Ty1 V1, Ty2 V2) {
    if (IsReverse) {
      RevMap[V2] = V1;
      return;
    }
    Map[V1] = V2;
  }
  MapTy Map;
  RevMapTy RevMap;
  bool IsReverse;
};

// Add a number as a string to a string
template<class T>
std::string
concat(const std::string& s, const T& n) {
  std::stringstream ss;
  ss << s << n;
  return ss.str();
}

inline std::string
operator+(const std::string& s, int n) {
  return concat(s, n);
}

inline std::string
operator+(const std::string& s, unsigned n) {
  return concat(s, n);
}

template<class MapTy>
unsigned mapBitMask(unsigned BM) {
  unsigned Res = 0;
  MapTy::foreach([&](typename MapTy::KeyTy K, typename MapTy::ValueTy V){
    Res |= BM & (unsigned)K ? (unsigned)V : 0;
  });
  return Res;
}

template<class MapTy>
unsigned rmapBitMask(unsigned BM) {
  unsigned Res = 0;
  MapTy::foreach([&](typename MapTy::KeyTy K, typename MapTy::ValueTy V){
    Res |= BM & (unsigned)V ? (unsigned)K : 0;
  });
  return Res;
}

// Get the number of words used for encoding a string literal in SPRV
inline size_t
getSizeInWords(const std::string& Str) { return Str.length()/4 + 1;}

}


#endif /* SPRVUTIL_HPP_ */
