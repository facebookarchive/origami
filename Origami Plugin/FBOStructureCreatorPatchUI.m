/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOStructureCreatorPatchUI.h"

@implementation FBOStructureCreatorPatchUI

+ (NSString *)viewNibName {
  return @"FBOStructureCreatorPatchUI";
}

+ (NSString *)viewTitle {
  return @"Settings";
}

- (void)setupViewForPatch:(QCPatch *)patch {
  self.inputCount = [patch integerForStateKey:@"inputCount"];
  [self addObserver:patch forKeyPath:@"inputCount" options:NSKeyValueObservingOptionNew context:nil];

  Class portClass = [patch valueForStateKey:@"portClass"];
  self.inputType = [self nameForPortClass:portClass];
  [self addObserver:patch forKeyPath:@"inputType" options:NSKeyValueObservingOptionNew context:nil];
  
  self.keyed = [patch boolForStateKey:@"keyed"];
  [self addObserver:patch forKeyPath:@"keyed" options:NSKeyValueObservingOptionNew context:nil];
  
  [super setupViewForPatch:patch];
}

- (void)resetView {
  [self _removeObservers];
  
  [super resetView];
}

- (NSString *)nameForPortClass:(Class)class {
  NSString *type = NSStringFromClass(class);
  type = [type substringFromIndex:2]; // Remove "QC"
  type = [type substringToIndex:(type.length - 4)]; // Remove "Port"
  return type;
}

/**
 Removes possible observers created by the setup process.
 */
- (void)_removeObservers {
  @try {
    [self removeObserver:self.patch forKeyPath:@"self.inputCount"];
    [self removeObserver:self.patch forKeyPath:@"self.inputType"];
    [self removeObserver:self.patch forKeyPath:@"self.keyed"];
  }
  @catch (NSException * __unused exception) {}
}

@end
