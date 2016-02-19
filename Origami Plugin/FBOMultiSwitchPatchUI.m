/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOMultiSwitchPatchUI.h"
#import "FBOMultiSwitchPatch.h"

@implementation FBOMultiSwitchPatchUI

#pragma mark - QCInspector Setup

+ (NSString *)viewNibName { return @"FBOMultiSwitchPatchUI"; }
+ (NSString *)viewTitle { return @"Settings"; }

#pragma mark -QCInspector Behavior

- (void)setupViewForPatch:(QCPatch *)patch {
  self.inputCount = [patch integerForStateKey:@"inputCount"];
  [self addObserver:patch forKeyPath:@"inputCount" options:NSKeyValueObservingOptionNew context:nil];
  [super setupViewForPatch:patch];
}

- (void)resetView {
  [self _removeObservers];
  [super resetView];
}

/**
 Removes possible observers created by the setup process.
 */
- (void)_removeObservers {
  @try {
    [self removeObserver:self.patch forKeyPath:@"self.inputCount"];
  }
  @catch (NSException * __unused exception) {}
}

@end
