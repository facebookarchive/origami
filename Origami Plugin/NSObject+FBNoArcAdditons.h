/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <Foundation/Foundation.h>

@interface NSObject (FBNoArcAdditons)

// Read out an ivar on a given object.
//
//   Usage example:
//   unsigned long long currentIndex = *(unsigned long long *)[self.parentPatch fb_instanceVariableForKey:@"_currentIndex"];
//
- (void *)fb_instanceVariableForKey:(NSString *)aKey;

@end
