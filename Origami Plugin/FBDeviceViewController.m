/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBDeviceViewController.h"
#import "BWDeviceInfoReceiver.h"

@interface FBDeviceViewController ()
@property (strong, nonatomic) id deviceDescriptionObserver;
@end

@implementation FBDeviceViewController

- (void)loadView {
  [super loadView];
  
  [self.view addSubview:self.noDeviceView];
  [self.view addSubview:self.deviceIsConnectedView];
  
  [[BWDeviceInfoReceiver sharedReceiver] addObserver:self forKeyPath:@"deviceDescription" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial) context:NULL];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ([keyPath isEqualToString:@"deviceDescription"]) {
    NSDictionary *deviceDescription = change[@"new"];
    
    if ([deviceDescription isKindOfClass:[NSDictionary class]] && deviceDescription[@"name"]) {
      self.deviceName.stringValue = deviceDescription[@"name"];
      self.deviceIsConnectedView.hidden = NO;
      self.noDeviceView.hidden = YES;
    } else {
      self.deviceIsConnectedView.hidden = YES;
      self.noDeviceView.hidden = NO;
    }
  }
}

- (void)dealloc {
  [[BWDeviceInfoReceiver sharedReceiver] removeObserver:self forKeyPath:@"deviceDescription"];
}

@end
