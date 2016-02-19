/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBDeviceToolbarButton.h"
#import "BWDeviceInfoReceiver.h"

@implementation FBDeviceToolbarButton

- (id)initWithFrame:(NSRect)frameRect {
  if (self = [super initWithFrame:frameRect]) {
    [[BWDeviceInfoReceiver sharedReceiver] addObserver:self forKeyPath:@"deviceDescription" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial) context:NULL];
  }
  return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ([keyPath isEqualToString:@"deviceDescription"]) {
    NSDictionary *deviceDescription = change[@"new"];
    
    if ([deviceDescription isKindOfClass:[NSDictionary class]] && deviceDescription[@"name"])
      self.title = deviceDescription[@"name"];
    else
      self.title = @"No Device";
  }
}

- (void)dealloc {
  [[BWDeviceInfoReceiver sharedReceiver] removeObserver:self forKeyPath:@"deviceDescription"];
}

@end