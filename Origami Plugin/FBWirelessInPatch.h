/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBWirelessController.h"

@interface FBWirelessInPatch : QCPatch {
  QCPort *_inPort;
  NSString *_previousName;
  NSString *_selectedInputType;
}

@property (copy, nonatomic) NSString *selectedInputType;
@property (assign, nonatomic) FBWirelessController *controller;

- (void)setPortClass:(Class)aClass;

@end
