/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

// There is one FBWirelessController instance per document.

#import <Foundation/Foundation.h>

@interface FBWirelessController : NSObject {
}

@property (strong) NSMutableDictionary *keyedData; // Key: Port name  Value: Data
@property (strong) NSMutableDictionary *keyedBroadcasters; // Key: Port name  Value: FBWirelessInPatch instance
@property (strong) NSString *lastCreatedKey;

+ (FBWirelessController *)controllerForPatch:(QCPatch *)patch;
+ (FBWirelessController *)controllerForDocument:(NSDocument *)document;

@end
