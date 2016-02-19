/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <Foundation/Foundation.h>
#import "PTChannel.h"
#import "FBDeviceProtocol.h"
#import "FBMutableOrderedDictionary.h"

extern NSString * const FBTweaksReceivedNotification;

@interface BWDeviceInfoReceiver : NSObject <PTChannelDelegate>

@property (retain, nonatomic) NSDictionary *deviceInfo;
@property (retain, nonatomic) NSDictionary *deviceDescription;
@property (retain, nonatomic) NSMutableDictionary *layerChanges;
@property (retain, nonatomic) FBMutableOrderedDictionary *layerTreeQueue;
@property (retain, nonatomic) NSMutableDictionary *parentRIIs;
@property (retain, nonatomic) NSMutableArray *sentImageHashes;
@property (retain, nonatomic) NSDictionary *tweaksList;
@property (retain, nonatomic) NSMutableDictionary *imagesInTransit; // Key: image hash, Object: layer ID
@property (retain, nonatomic) NSMutableDictionary *layersThatJustHadLimitRemoved; // Key: layer ID, Object: throw away

+ (BWDeviceInfoReceiver *)sharedReceiver;
- (void)initialSetup;
- (BOOL)isConnected;
- (void)patchRequestsConnection;

- (void)sendData:(id)data forFrameType:(FBFrameType)frameType;
- (void)sendData:(id)data forFrameType:(FBFrameType)frameType withTag:(uint32_t)tag;

- (void)encodeAndSendImage:(QCImage *)image hash:(NSString *)imageHash layerKey:(NSString *)layerKey;

@end
