/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <Foundation/Foundation.h>

@interface NSURL (FBAdditions)

+ (NSURL *)URLWithQuartzComposerLocation:(NSString *)location relativeToDocument:(NSDocument *)document;
+ (NSURL *)URLWithEventDescriptor:(NSAppleEventDescriptor *)appleEventDescriptor;

@end
