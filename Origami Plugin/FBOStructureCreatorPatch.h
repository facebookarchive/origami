/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBODynamicPortsPatch.h"

@interface FBOStructureCreatorPatch : FBODynamicPortsPatch {
  QCStructurePort *outputStructure;
  Class _portClassInternal;
}

@property (nonatomic) NSUInteger inputCount;
@property (nonatomic) BOOL keyed;

- (Class)portClass;
- (void)setPortClass:(Class)aClass;

@end
