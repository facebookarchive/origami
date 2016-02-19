/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <SkankySDK/SkankySDK.h>

@interface QCPort (FBAdditions)

- (NSArray *)fb_connectedPorts;
- (BOOL)fb_isInputPort;
- (NSString *)fb_name;

@end
