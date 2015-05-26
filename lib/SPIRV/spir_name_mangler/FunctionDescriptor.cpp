//===---------------------- FunctionDescriptor.cpp -----------------------===//
//
//                              SPIR Tools
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===---------------------------------------------------------------------===//

#include "FunctionDescriptor.h"
#include "ParameterType.h"
#include <sstream>

namespace SPIR {

std::string FunctionDescriptor::nullString() {
  return std::string("<invalid>");
}

std::string FunctionDescriptor::toString() const {
  std::stringstream stream;
  if (isNull()) {
    return FunctionDescriptor::nullString();
  }
  stream << name << "(";
  size_t paramCount = parameters.size();
  if (paramCount > 0) {
    for (size_t i=0 ; i<paramCount-1 ; ++i)
      stream << parameters[i]->toString() << ", ";
    stream << parameters[paramCount-1]->toString();
  }
  stream << ")";
  return stream.str();
}

static bool equal(const TypeVector& l, const TypeVector& r) {
  if (&l == &r)
    return true;
  if (l.size() != r.size())
    return false;
  TypeVector::const_iterator itl = l.begin(), itr = r.begin(),
  endl = l.end();
  while (itl != endl) {
    if (!(*itl)->equals(*itr))
      return false;
    ++itl;
    ++itr;
  }
  return true;
}

//
// FunctionDescriptor
//

bool FunctionDescriptor::operator == (const FunctionDescriptor& that) const {
  if (this == &that)
    return true;
  if (name != that.name)
    return false;
  return equal(parameters, that.parameters);
}

bool FunctionDescriptor::operator < (const FunctionDescriptor& that) const {
  int strCmp = name.compare(that.name);
  if (strCmp)
    return (strCmp < 0);
  size_t len = parameters.size(), thatLen = that.parameters.size();
  if (len != thatLen)
    return len < thatLen;
  TypeVector::const_iterator it = parameters.begin(),
  e = parameters.end(), thatit = that.parameters.begin();
  while (it != e) {
    int cmp = (*it)->toString().compare((*thatit)->toString());
    if (cmp)
      return (cmp < 0);
    ++thatit;
    ++it;
  }
  return false;
}

bool FunctionDescriptor::isNull() const {
  return (name.empty() && parameters.empty());
}

FunctionDescriptor FunctionDescriptor::null() {
  FunctionDescriptor fd;
  fd.name = "";
  return fd;
}

} // End SPIR namespace
