/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOLiveFilePatchUI.h"
#import "FBOLiveFilePatch.h"

@implementation FBOLiveFilePatchUI

#pragma mark - QCInspector Setup

+ (NSString *)viewNibName { return @"FBOLiveFilePatchUI"; }
+ (NSString *)viewTitle { return @"Settings"; }

#pragma mark -QCInspector Behavior

- (void)setupViewForPatch:(QCPatch *)patch {
  self.disableEmbedding = [NSNumber numberWithBool:[patch boolForStateKey:@"disableEmbedding"]];
  self.useAbsolutePath = [NSNumber numberWithBool:[patch boolForStateKey:@"useAbsolutePath"]];
  self.filePath = (NSString *)[patch valueForStateKey:@"filePath"];

  [self addObserver:patch forKeyPath:@"filePath" options:NSKeyValueObservingOptionNew context:nil];
  [self addObserver:patch forKeyPath:@"useAbsolutePath" options:NSKeyValueObservingOptionNew context:nil];
  [self addObserver:patch forKeyPath:@"disableEmbedding" options:NSKeyValueObservingOptionNew context:nil];
  [super setupViewForPatch:patch];
}

- (void)resetView {
  [self _removeObservers];
  [super resetView];
}

- (IBAction)chooseFile:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  FBOLiveFilePatchUI* __weak weakSelf = self;
  [panel beginWithCompletionHandler:^(NSInteger result) {
    weakSelf.filePath = [[panel URL] path];
  }];
}

/**
 Removes possible observers created by the setup process.
 */
- (void)_removeObservers {
  @try {
    [self removeObserver:self.patch forKeyPath:@"self.filePath"];
    [self removeObserver:self.patch forKeyPath:@"self.useAbsolutePath"];
    [self removeObserver:self.patch forKeyPath:@"self.disableEmbedding"];
  }
  @catch (NSException * __unused exception) {}
}

@end
