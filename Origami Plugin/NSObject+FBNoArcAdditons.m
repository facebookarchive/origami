/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "NSObject+FBNoArcAdditons.h"

@implementation NSObject (FBNoArcAdditons)

- (void *)fb_instanceVariableForKey:(NSString *)aKey {
  if (aKey) {
    Ivar ivar = object_getInstanceVariable(self, [aKey UTF8String], NULL);
    if (ivar) {
      return (void *)((char *)self + ivar_getOffset(ivar));
    }
  }
  return NULL;
}

@end
