/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#ifndef FBTools_GRPHookMethod_h
#define FBTools_GRPHookMethod_h

#import <objc/runtime.h>

#define GRPHookMethod(cls, sel, ...) ((^{ SEL _cmd = sel; __block IMP __original = _GRPHookMethod(cls, sel, __VA_ARGS__); })())
#define GRPCallOriginal(...) __original(self, _cmd, ##__VA_ARGS__)

static IMP _GRPHookMethod(Class cls, SEL sel, id imp){
  for (Method method = class_getInstanceMethod(cls, sel); method != NULL;) {
    return method_setImplementation(method, imp_implementationWithBlock(imp));
  }
  return NULL;
}

#endif
