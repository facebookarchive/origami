/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "BWDeviceInfoTransmitter.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import <QuartzCore/QuartzCore.h>

#import "BWPeerTalkAdditions.h"
#import "BWViewController.h"
#import "FBDeviceProtocol.h"

static BWDeviceInfoTransmitter *sharedSingleton;

static CGFloat RadiansToDegrees(double radians) {
  return radians * 180 / M_PI;
};

@interface BWDeviceInfoTransmitter () {
  __weak PTChannel *serverChannel_;
  __weak PTChannel *peerChannel_;
}
- (void)sendData:(id)data forFrameType:(FBFrameType)frameType;
@end

@implementation BWDeviceInfoTransmitter

@synthesize touches = _touches;
@synthesize motionManager = _motionManager;
@synthesize screenScale = _screenScale;
@synthesize deviceInformation = _deviceInformation;
@synthesize deviceData = _deviceData;
@synthesize recorder = _recorder;

+ (void)initialize
{
  static BOOL initialized = NO;
  if (!initialized) {
    initialized = YES;
    sharedSingleton = [[BWDeviceInfoTransmitter alloc] init];
  }
}

+ (BWDeviceInfoTransmitter *)sharedTransmitter {
  return sharedSingleton;
}

- (void)initialSetup {
  [self listen];
  self.screenScale = [[UIScreen mainScreen] scale];

  self.motionManager = [[CMMotionManager alloc] init];
  [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical];

  CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateScreen:)];
  [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];

  UIScreen *screen = [UIScreen mainScreen];
  UIDevice *device = [UIDevice currentDevice];
  self.deviceInformation = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            @(device.userInterfaceIdiom), @"isTablet",
                            @((screen.scale > 1.01)), @"retina",
                            device.name, @"name",
                            device.systemName, @"systemName",
                            device.systemVersion, @"systemVersion",
                            device.model, @"model",
                            device.localizedModel, @"localizedModel",
                            nil];

  BOOL isPortrait = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]);
  self.deviceData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                     @(isPortrait), @"isPortrait",
                     @(screen.bounds.size.width * screen.scale),@"screenWidth",
                     @(screen.bounds.size.height * screen.scale),@"screenHeight",
                     nil];
}

- (void)listen {
  PTChannel *channel = [PTChannel channelWithDelegate:self];
  [channel listenOnPort:FBProtocolIPv4PortNumber IPv4Address:INADDR_LOOPBACK callback:^(NSError *error) {
    if (error) {
//      NSLog(@"Failed to listen on 127.0.0.1:%d: %@", FBProtocolIPv4PortNumber, error);
    } else {
//      NSLog(@"Listening on 127.0.0.1:%d", FBProtocolIPv4PortNumber);
      serverChannel_ = channel;
    }
  }];
}

- (void)updateScreen:(CADisplayLink *)displayLink {
  [self collectSensorData];
  [self sendData:self.deviceData forFrameType:FBFrameTypeSensorData];
}

- (void)collectSensorData {
  NSArray *touches = self.touches.allValues;
  BWViewController *mainViewController = self.mainViewController;
  CGSize viewSize = mainViewController.view.bounds.size;

  // Touches -- Should probably be moved out of here
  NSMutableDictionary *deviceInfoTouches = [NSMutableDictionary dictionary];

  for (UITouch *touch in touches) {
    CGPoint position = [touch locationInView:mainViewController.view];

    // Convert to the QC co-ordinate system. Origin in the center, max point top right.
    position.x = position.x - viewSize.width / 2;
    position.y = viewSize.height - (position.y + (viewSize.height / 2));

    NSNumber *positionX = @(position.x * self.screenScale);
    NSNumber *positionY = @(position.y * self.screenScale);
    NSNumber *phase = @(touch.phase);
    NSNumber *size = [touch respondsToSelector:@selector(majorRadius)] ? @(touch.majorRadius) : @0.0;
    NSNumber *sizeTolerance = [touch respondsToSelector:@selector(majorRadiusTolerance)] ? @(touch.majorRadiusTolerance) : @0.0;

    NSDictionary *touchDictionary = @{@"x": positionX, @"y": positionY, @"phase": phase, @"size": size, @"sizeTolerance": sizeTolerance};

#if FB_IOS9_SDK_OR_LATER

    if ([touch respondsToSelector:@selector(force)]) {
      NSNumber *force = @(touch.force);
      [touchDictionary setValue:force forKey:@"force"];
    }

    if ([touch respondsToSelector:@selector(maximumPossibleForce)]) {
      NSNumber *maxForce = @(touch.maximumPossibleForce);
      [touchDictionary setValue:maxForce forKey:@"maximumPossibleForce"];
    }

#endif

    NSString *pointerAddress = [NSString stringWithFormat:@"%p", touch];
    deviceInfoTouches[pointerAddress] = touchDictionary;
  }

  (self.deviceData)[@"touches"] = deviceInfoTouches;

  // Gyroscope
  CMAttitude *attitude = self.motionManager.deviceMotion.attitude;
  NSNumber *pitch = [NSNumber numberWithDouble:RadiansToDegrees(attitude.pitch)];
  NSNumber *roll = [NSNumber numberWithDouble:RadiansToDegrees(attitude.roll)];
  NSNumber *yaw = [NSNumber numberWithDouble:RadiansToDegrees(attitude.yaw)];
  NSNumber *quaternionX = [NSNumber numberWithDouble:attitude.quaternion.x];
  NSNumber *quaternionY = [NSNumber numberWithDouble:attitude.quaternion.y];
  NSNumber *quaternionZ = [NSNumber numberWithDouble:attitude.quaternion.z];
  NSNumber *quaternionW = [NSNumber numberWithDouble:attitude.quaternion.w];
  NSDictionary *deviceInfoGyroscope = @{@"pitch": pitch, @"roll": roll, @"yaw": yaw, @"quaternionX": quaternionX, @"quaternionY": quaternionY, @"quaternionZ": quaternionZ, @"quaternionW": quaternionW};
  (self.deviceData)[@"gyroscope"] = deviceInfoGyroscope;

  // Acceleromter
  CMAcceleration acceleration = self.motionManager.deviceMotion.userAcceleration;
  NSNumber *x = @(acceleration.x);
  NSNumber *y = @(acceleration.y);
  NSNumber *z = @(acceleration.z);
  NSDictionary *deviceInfoAcceleration = @{@"x": x, @"y": y, @"z": z};
  (self.deviceData)[@"acceleration"] = deviceInfoAcceleration;

  // Rotation Rate
  CMRotationRate rotationRate = self.motionManager.deviceMotion.rotationRate;
  NSNumber *rateX = @(rotationRate.x);
  NSNumber *rateY = @(rotationRate.y);
  NSNumber *rateZ = @(rotationRate.z);
  NSDictionary *deviceInfoRotationRate = @{@"x": rateX, @"y": rateY, @"z": rateZ};
  (self.deviceData)[@"rotationRate"] = deviceInfoRotationRate;
}

- (void)sendData:(id)data forFrameType:(FBFrameType)frameType {
  if ([data respondsToSelector:@selector(createReferencingDispatchData)]) {
    dispatch_data_t payload = [data createReferencingDispatchData];
    [peerChannel_ sendFrameOfType:frameType tag:PTFrameNoTag withPayload:payload callback:^(NSError *error) {
      if (error) {
//        NSLog(@"Failed to send data for frame type %u: %@",frameType,error);
      }
    }];
  }
}

#pragma mark - PTChannelDelegate

// Invoked to accept an incoming frame on a channel. Reply NO ignore the
// incoming frame. If not implemented by the delegate, all frames are accepted.
- (BOOL)ioFrameChannel:(PTChannel*)channel shouldAcceptFrameOfType:(uint32_t)type tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize {
  if (channel != peerChannel_) {
    // A previous channel that has been canceled but not yet ended. Ignore.
    return NO;
  } else if (type != FBFrameTypeLayerTree &&
             type != FBFrameTypeLayerChanges &&
             type != FBFrameTypeLayerRemoval &&
             type != FBFrameTypeImage &&
             type != FBFrameTypeVibration) {
//    NSLog(@"Unexpected frame of type %u", type);
    [channel close];
    return NO;
  } else {
    return YES;
  }
}

// Invoked when a new frame has arrived on a channel.
- (void)ioFrameChannel:(PTChannel*)channel didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData*)payload {
  BWViewController *mainViewController = self.mainViewController;

  if (type == FBFrameTypeLayerTree) {
    NSArray *layerTree = [NSArray arrayWithContentsOfDispatchData:payload.dispatchData];

    [mainViewController removeAllViews];
//    NSLog(@"[Tree] Removing all layers. Setting up tree: %@",layerTree);
    [mainViewController createViewHierarchyFromTree:layerTree];
  }

  else if (type == FBFrameTypeLayerChanges) {
    NSDictionary *layers = [NSDictionary dictionaryWithContentsOfDispatchData:payload.dispatchData];
    [mainViewController applyChanges:layers];
//    NSLog(@"[Change]");
  }

  else if (type == FBFrameTypeLayerRemoval) {
    NSArray *patchIDs = [NSArray arrayWithContentsOfDispatchData:payload.dispatchData];
//    NSLog(@"[Removal]: %@",patchIDs);
    for (NSString *patchID in patchIDs) {
      [mainViewController removeViewWithID:patchID];
    }
  }

  else if (type == FBFrameTypeImage) {
    assert(payload != nil);
    NSData *imageData = [NSData dataWithContentsOfDispatchData:payload.dispatchData];

    if (imageData) {
      NSDictionary *dict = [NSDictionary dictionaryWithContentsOfDispatchData:payload.dispatchData];

      // Data only has one image at the moment.
      for (NSString *imageKey in dict.allKeys) {
        NSArray *parts = [imageKey componentsSeparatedByString:@","];
        NSString *imageHash = parts[0];
        NSString *layerKey = parts[1];

        NSData *innerImageData = dict[imageKey];
        UIImage *image = [UIImage imageWithData:innerImageData];
        [mainViewController setImage:image withHash:imageHash layerKey:layerKey];
//        NSLog(@"[Image]: Set image with hash: %@ Layer Key: %@",imageHash,layerKey);
      }

      // Tell the Mac that we successfully received the image(s), and we're ready for another one for those layers
      [self sendData:dict.allKeys forFrameType:FBFrameTypeImageReceived];
    }
  }

  else if (type == FBFrameTypeVibration) {
    NSDictionary *vibDict = [NSDictionary dictionaryWithContentsOfDispatchData:payload.dispatchData];
    BOOL state = [(NSNumber *)vibDict[@"state"] boolValue];

    if (state) {
      AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    }
  }
}

// Invoked when the channel closed. If it closed because of an error, *error* is
// a non-nil NSError object.
- (void)ioFrameChannel:(PTChannel*)channel didEndWithError:(NSError*)error {
  if (error) {
//    NSLog(@"%@ ended with error: %@", channel, error);
  } else {
//    NSLog(@"Disconnected from %@", channel.userInfo);
    BWViewController *mainViewController = self.mainViewController;
    if (mainViewController.view.subviews.count < 1) {
      [self.delegate deviceInfoTransmitterDidDisconnect:self];
//      [appDelegate setConnected:NO];
    }

    [self listen];
  }
}

// For listening channels, this method is invoked when a new connection has been
// accepted.
- (void)ioFrameChannel:(PTChannel*)channel didAcceptConnection:(PTChannel*)otherChannel fromAddress:(PTAddress*)address {
  // Cancel any other connection. We are FIFO, so the last connection
  // established will cancel any previous connection and "take its place".
  if (peerChannel_) {
    [peerChannel_ cancel];
  }

  // Weak pointer to current connection. Connection objects live by themselves
  // (owned by its parent dispatch queue) until they are closed.
  peerChannel_ = otherChannel;
  peerChannel_.userInfo = address;
//  NSLog(@"Connected to %@", address);

//  BWAppDelegate *appDelegate = (BWAppDelegate *)[[UIApplication sharedApplication] delegate];
//  [appDelegate setConnected:YES];
  [self.delegate deviceInfoTransmitterDidConnect:self];

  // Send some information about ourselves to the other end
  [self sendData:self.deviceInformation forFrameType:FBFrameTypeDeviceInfo];
}


@end
//
