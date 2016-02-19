/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "BWPeerTalkAdditions.h"

#import <peertalk/PTChannel.h>

@implementation NSArray (BWPeerTalkAdditions)

- (dispatch_data_t)createReferencingDispatchData {
    NSError *error = nil;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:self format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    if (!plistData) {
//        NSLog(@"Failed to serialize property list: %@", error);
        return nil;
    } else {
        return [plistData createReferencingDispatchData];
    }
}

// Decode *data* as a property list-encoded array. Returns nil on failure.
+ (NSArray *)arrayWithContentsOfDispatchData:(dispatch_data_t)data {
    if (!data) {
        return nil;
    }
    uint8_t *buffer = NULL;
    size_t bufferSize = 0;
    dispatch_data_t contiguousData = dispatch_data_create_map(data, (const void **)&buffer, &bufferSize);
    if (!contiguousData) {
        return nil;
    }
    NSArray *array = [NSPropertyListSerialization propertyListWithData:[NSData dataWithBytesNoCopy:(void *)buffer length:bufferSize freeWhenDone:NO] options:NSPropertyListImmutable format:NULL error:nil];
    //  dispatch_release(contiguousData);
    return array;
}

@end
