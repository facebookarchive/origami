/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <Foundation/Foundation.h>

@interface NSDictionary (BWPeerTalkAdditions)
// Decode *data* as a property list-encoded dictionary. Returns nil on failure.
+ (NSDictionary *)dictionaryWithContentsOfDispatchData:(dispatch_data_t)data;
@end

@interface NSArray (BWPeerTalkAdditions)
// See description of -[NSData(PTProtocol) createReferencingDispatchData]
- (dispatch_data_t)createReferencingDispatchData;

// Decode *data* as a property list-encoded array. Returns nil on failure.
+ (NSArray *)arrayWithContentsOfDispatchData:(dispatch_data_t)data;
@end
