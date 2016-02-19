/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

#import <peertalk/PTChannel.h>

@class AVAudioRecorder;
@class BWViewController;
@class CMMotionManager;

@protocol BWDeviceInfoTransmitterDelegate;

@interface BWDeviceInfoTransmitter : NSObject <PTChannelDelegate>

@property (weak, nonatomic) id<BWDeviceInfoTransmitterDelegate> delegate;
@property (weak, nonatomic) BWViewController *mainViewController;

@property (retain, nonatomic) NSDictionary *touches;
@property (retain, nonatomic) CMMotionManager *motionManager;
@property (retain, nonatomic) NSMutableDictionary *deviceInformation;
@property (retain, nonatomic) NSMutableDictionary *deviceData;
@property (retain, nonatomic) AVAudioRecorder *recorder;
@property CGFloat screenScale;

+ (BWDeviceInfoTransmitter *)sharedTransmitter;
- (void)initialSetup;
- (void)listen;

@end


@protocol BWDeviceInfoTransmitterDelegate <NSObject>

- (void)deviceInfoTransmitterDidConnect:(BWDeviceInfoTransmitter *)transmitte;
- (void)deviceInfoTransmitterDidDisconnect:(BWDeviceInfoTransmitter *)transmitte;

@end
