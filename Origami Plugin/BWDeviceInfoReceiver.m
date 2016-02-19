/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "BWDeviceInfoReceiver.h"
#import "PTUSBHub.h"
#import "FBDeviceRendererPatch.h"
#import "QCImage+FBAdditions.h"

static BWDeviceInfoReceiver *sharedSingleton;
static const NSTimeInterval PTAppReconnectDelay = 1.0;
static BOOL isListening = NO;
NSString * const FBTweaksReceivedNotification = @"FBTweaksReceivedNotification";

@interface BWDeviceInfoReceiver () {
  NSNumber *connectingToDeviceID_;
  NSNumber *connectedDeviceID_;
  NSDictionary *connectedDeviceProperties_;
  NSDictionary *remoteDeviceInfo_;
  dispatch_queue_t notConnectedQueue_;
  BOOL notConnectedQueueSuspended_;
  PTChannel *connectedChannel_;
}

@property (readonly) NSNumber *connectedDeviceID;
@property PTChannel *connectedChannel;

- (void)startListeningForDevices;
- (void)enqueueConnectToLocalIPv4Port;

@end

@implementation BWDeviceInfoReceiver

+ (void)initialize
{
  static BOOL initialized = NO;
  if (!initialized && [[NSProcessInfo processInfo].processName isEqualToString:@"Quartz Composer"]) {
    initialized = YES;
    sharedSingleton = [[BWDeviceInfoReceiver alloc] init];    
  }
}

+ (BWDeviceInfoReceiver *)sharedReceiver {
  return sharedSingleton;
}

- (void)initialSetup {
  self.layerChanges = [NSMutableDictionary dictionary];
  self.layerTreeQueue = [[FBMutableOrderedDictionary alloc] init];
  self.parentRIIs = [NSMutableDictionary dictionary];
  self.sentImageHashes = [NSMutableArray array];
  self.tweaksList = [NSMutableDictionary dictionary];
  self.imagesInTransit = [NSMutableDictionary dictionary];
  self.layersThatJustHadLimitRemoved = [NSMutableDictionary dictionary];
}

- (void)patchRequestsConnection {
  if (isListening == NO) {
    notConnectedQueue_ = dispatch_queue_create("PTExample.notConnectedQueue", DISPATCH_QUEUE_SERIAL);
    [self startListeningForDevices];
    [self enqueueConnectToLocalIPv4Port];
    
    isListening = YES;
  }
}

- (void)encodeAndSendImage:(QCImage *)image hash:(NSString *)imageHash layerKey:(NSString *)layerKey {
  NSArray *sentImageHashesImmutable = [NSArray arrayWithArray:[BWDeviceInfoReceiver sharedReceiver].sentImageHashes];
  BOOL imageIsCachedOnDevice = [sentImageHashesImmutable containsObject:imageHash];
  BOOL layerIsRateLimited = ([[BWDeviceInfoReceiver sharedReceiver].imagesInTransit allKeysForObject:layerKey].count > 0);

  if (!imageIsCachedOnDevice && !layerIsRateLimited) {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
      NSData *imageData = [image fb_imageData];
      if (imageData && imageHash) {
        [self.sentImageHashes addObject:imageHash];
        self.imagesInTransit[imageHash] = layerKey;
        
        NSString *imageKey = [NSString stringWithFormat:@"%@,%@",imageHash,layerKey];
        
        NSDictionary *dict = [NSDictionary dictionaryWithObject:imageData forKey:imageKey];
        [self sendData:dict forFrameType:FBFrameTypeImage withTag:PTFrameNoTag];
      }
    });
  }
}

- (void)clearCache {
  [self.sentImageHashes removeAllObjects];
  [self.imagesInTransit removeAllObjects];
  [self.layersThatJustHadLimitRemoved removeAllObjects];
}

- (void)sendData:(id)data forFrameType:(FBFrameType)frameType {
  [self sendData:data forFrameType:frameType withTag:PTFrameNoTag];
}

- (void)sendData:(id)data forFrameType:(FBFrameType)frameType withTag:(uint32_t)tag {
  if (!connectedChannel_)
    return;
  
  if ([data respondsToSelector:@selector(createReferencingDispatchData)]) {
    dispatch_data_t payload = [data createReferencingDispatchData];
    NSString *tagString = (tag == PTFrameNoTag) ? @"" : [NSString stringWithFormat:@"Tag: %u",tag];
    NSString *dataString = [data isKindOfClass:[NSData class]] ? [NSString stringWithFormat:@"%lu",[data length]] : [NSString stringWithFormat:@"%@",data];
    
    if (frameType != FBFrameTypeLayerChanges && frameType != FBFrameTypeImage)
      NSLog(@"%@. %@ Data: %@",[self nameOfFrameType:frameType],tagString,dataString);
    else if (frameType == FBFrameTypeImage)
      NSLog(@"Image. Hash: %@",[[data allKeys] lastObject]);
    
    [connectedChannel_ sendFrameOfType:frameType tag:tag withPayload:payload callback:^(NSError *error) {
      if (error) {
        NSLog(@"Failed to send data for frame type %u: %@",frameType,error);
      }
    }];
  }
}

- (NSString *)nameOfFrameType:(FBFrameType)frameType {
  if (frameType == FBFrameTypeLayerChanges) {
    return @"Changes";
  } else if (frameType == FBFrameTypeLayerRemoval) {
    return @"Removal";
  } else if (frameType == FBFrameTypeLayerTree) {
    return @"Layer Tree";
  } else if (frameType == FBFrameTypeImage) {
    return @"Image";
  } else if (frameType == FBFrameTypeImageReceived) {
    return @"Image Received";
  }
  
  return @"Nil frame type";
}

#pragma mark - PeerTalk

- (BOOL)isConnected {
  if (connectedChannel_ && connectedChannel_.isConnected) {
    return YES;
  }
  
  return NO;
}

- (PTChannel*)connectedChannel {
  return connectedChannel_;
}

- (void)setConnectedChannel:(PTChannel*)connectedChannel {
  connectedChannel_ = connectedChannel;
  
  // Toggle the notConnectedQueue_ depending on if we are connected or not
  if (!connectedChannel_ && notConnectedQueueSuspended_) {
    dispatch_resume(notConnectedQueue_);
    notConnectedQueueSuspended_ = NO;
  } else if (connectedChannel_ && !notConnectedQueueSuspended_) {
    dispatch_suspend(notConnectedQueue_);
    notConnectedQueueSuspended_ = YES;
  }
  
  if (!connectedChannel_ && connectingToDeviceID_) {
    [self enqueueConnectToUSBDevice];
  }
}

- (void)startListeningForDevices {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  
  [nc addObserverForName:PTUSBDeviceDidAttachNotification object:PTUSBHub.sharedHub queue:nil usingBlock:^(NSNotification *note) {
    NSNumber *deviceID = [note.userInfo objectForKey:@"DeviceID"];
    NSLog(@"PTUSBDeviceDidAttachNotification: %@", deviceID);
    
    dispatch_async(notConnectedQueue_, ^{
      if (!connectingToDeviceID_ || ![deviceID isEqualToNumber:connectingToDeviceID_]) {
        [self disconnectFromCurrentChannel];
        connectingToDeviceID_ = deviceID;
        connectedDeviceProperties_ = [note.userInfo objectForKey:@"Properties"];
        [self enqueueConnectToUSBDevice];
      }
    });
  }];
  
  [nc addObserverForName:PTUSBDeviceDidDetachNotification object:PTUSBHub.sharedHub queue:nil usingBlock:^(NSNotification *note) {
    NSNumber *deviceID = [note.userInfo objectForKey:@"DeviceID"];
    NSLog(@"PTUSBDeviceDidDetachNotification: %@", deviceID);
    
    if ([connectingToDeviceID_ isEqualToNumber:deviceID]) {
      connectedDeviceProperties_ = nil;
      connectingToDeviceID_ = nil;
      if (connectedChannel_) {
        [connectedChannel_ close];
      }
    }
  }];
}

- (void)enqueueConnectToLocalIPv4Port {
  dispatch_async(notConnectedQueue_, ^{
    dispatch_async(dispatch_get_main_queue(), ^{
      [self connectToLocalIPv4Port];
    });
  });
}


- (void)connectToLocalIPv4Port {
  PTChannel *channel = [PTChannel channelWithDelegate:self];
  channel.userInfo = [NSString stringWithFormat:@"127.0.0.1:%d", FBProtocolIPv4PortNumber];
  [channel connectToPort:FBProtocolIPv4PortNumber IPv4Address:INADDR_LOOPBACK callback:^(NSError *error, PTAddress *address) {
    if (error) {
      if (error.domain == NSPOSIXErrorDomain && (error.code == ECONNREFUSED || error.code == ETIMEDOUT)) {
        // this is an expected state
      } else {
        NSLog(@"Failed to connect to 127.0.0.1:%d: %@", FBProtocolIPv4PortNumber, error);
      }
    } else {
      [self disconnectFromCurrentChannel];
      self.connectedChannel = channel;
      channel.userInfo = address;
      NSLog(@"Connected to %@", address);
    }
    [self performSelector:@selector(enqueueConnectToLocalIPv4Port) withObject:nil afterDelay:PTAppReconnectDelay];
  }];
}

- (void)enqueueConnectToUSBDevice {
  dispatch_async(notConnectedQueue_, ^{
    dispatch_async(dispatch_get_main_queue(), ^{
      [self connectToUSBDevice];
    });
  });
}

- (void)connectToUSBDevice {
  PTChannel *channel = [PTChannel channelWithDelegate:self];
  channel.userInfo = connectingToDeviceID_;
  channel.delegate = self;
  
  [channel connectToPort:FBProtocolIPv4PortNumber overUSBHub:PTUSBHub.sharedHub deviceID:connectingToDeviceID_ callback:^(NSError *error) {
    if (error) {
      if (error.domain == PTUSBHubErrorDomain && error.code == PTUSBHubErrorConnectionRefused) {
//        NSLog(@"Failed to connect to device #%@: %@", channel.userInfo, error);
      } else {
//        NSLog(@"Failed to connect to device #%@: %@", channel.userInfo, error);
      }
      if (channel.userInfo == connectingToDeviceID_) {
        [self performSelector:@selector(enqueueConnectToUSBDevice) withObject:nil afterDelay:PTAppReconnectDelay];
      }
    } else {
      connectedDeviceID_ = connectingToDeviceID_;
      self.connectedChannel = channel;
      //NSLog(@"Connected to device #%@\n%@", connectingToDeviceID_, connectedDeviceProperties_);
    }
  }];
}

- (void)didDisconnectFromDevice:(NSNumber*)deviceID {
  NSLog(@"Disconnected from device");
  self.deviceDescription = nil;
  
  if ([connectedDeviceID_ isEqualToNumber:deviceID]) {
    [self willChangeValueForKey:@"connectedDeviceID"];
    connectedDeviceID_ = nil;
    NSLog(@"connected id set to nil");
    [self didChangeValueForKey:@"connectedDeviceID"];
  }
}

- (void)disconnectFromCurrentChannel {
  if (connectedDeviceID_ && connectedChannel_) {
    [connectedChannel_ close];
    self.connectedChannel = nil;
  }
}


#pragma mark PTChannelDelegate

- (BOOL)ioFrameChannel:(PTChannel*)channel shouldAcceptFrameOfType:(uint32_t)type tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize {
  if (   type != FBFrameTypeDeviceInfo
      && type != FBFrameTypeSensorData
      && type != FBFrameTypeImageReceived
      && type != PTFrameTypeEndOfStream) {
    NSLog(@"Unexpected frame of type %u", type);
    [channel close];
    return NO;
  } else {
    return YES;
  }
}

- (void)ioFrameChannel:(PTChannel*)channel didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData*)payload {
  //NSLog(@"received %@, %u, %u, %@", channel, type, tag, payload);
  if (type == FBFrameTypeDeviceInfo) {
    NSDictionary *deviceInfo = [NSDictionary dictionaryWithContentsOfDispatchData:payload.dispatchData];
    NSLog(@"Connected to %@", deviceInfo.description);
    self.deviceDescription = deviceInfo;
    [self clearCache];
    [FBDeviceRendererPatch setNeedsTreeSerialization];
  }
  else if (type == FBFrameTypeSensorData) {
    self.deviceInfo = [NSDictionary dictionaryWithContentsOfDispatchData:payload.dispatchData];
  }
  else if (type == FBFrameTypeImageReceived) {
    NSArray *array = [NSArray arrayWithContentsOfDispatchData:payload.dispatchData];
    
    for (NSString *imageKey in array) {
      NSArray *parts = [imageKey componentsSeparatedByString:@","];
      NSString *imageHash = parts[0];

      NSString *layerID = self.imagesInTransit[imageHash];
      
      if (layerID) {
        [self.imagesInTransit removeObjectForKey:imageHash];
        self.layersThatJustHadLimitRemoved[layerID] = @YES;
      }
    }
  }
}

- (void)ioFrameChannel:(PTChannel*)channel didEndWithError:(NSError*)error {
  if (connectedDeviceID_ && [connectedDeviceID_ isEqualToNumber:channel.userInfo]) {
    [self didDisconnectFromDevice:connectedDeviceID_];
  }
  
  if (connectedChannel_ == channel) {
    NSLog(@"Disconnected from %@", channel.userInfo);
    self.connectedChannel = nil;
    NSLog(@"connected channel set to nil");
  }
}

@end
