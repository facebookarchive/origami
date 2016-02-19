/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBDeviceInfoPatch.h"
#import "BWDeviceInfoReceiver.h"

@implementation FBDeviceInfoPatch

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8
{
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8
{
	return kQCPatchExecutionModeProvider;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8
{
	return kQCPatchTimeModeIdle;
}

- (id)initWithIdentifier:(id)fp8
{
	if (self = [super initWithIdentifier:fp8]) {
    [[self userInfo] setObject:@"Device Info" forKey:@"name"];

    [[BWDeviceInfoReceiver sharedReceiver] patchRequestsConnection];
  }
  
	return self;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments
{
  NSDictionary *deviceDictionary = [BWDeviceInfoReceiver sharedReceiver].deviceDescription;
  
  BOOL isConnected = (deviceDictionary != nil);
  [outputConnected setBooleanValue:isConnected];
  
  NSNumber *isPad = [deviceDictionary objectForKey:@"isTablet"];
  [outputIsPad setBooleanValue:isPad.boolValue];
  
  NSNumber *isRetina = [deviceDictionary objectForKey:@"isRetina"];
  [outputIsRetina setBooleanValue:isRetina.boolValue];
  

  NSDictionary *dataDictionary = [BWDeviceInfoReceiver sharedReceiver].deviceInfo;

  NSNumber *width = [dataDictionary objectForKey:@"screenWidth"];
  [outputWidth setDoubleValue:width.doubleValue];
  
  NSNumber *height = [dataDictionary objectForKey:@"screenHeight"];
  [outputHeight setDoubleValue:height.doubleValue];
  
  NSNumber *isPortrait = [dataDictionary objectForKey:@"isPortrait"];
  [outputIsPortrait setBooleanValue:isPortrait.boolValue];
  
  NSDictionary *touches = [NSDictionary dictionary];
  if ([dataDictionary objectForKey:@"touches"]) {
    touches = [dataDictionary objectForKey:@"touches"];
  }
  QCStructure *touchesStructure = [[QCStructure alloc] initWithDictionary:touches];
  [outputTouches setStructureValue:touchesStructure];
  
  NSDictionary *gyroscope = [NSDictionary dictionary];
  if ([dataDictionary objectForKey:@"gyroscope"]) {
    gyroscope = [dataDictionary objectForKey:@"gyroscope"];
  }
  QCStructure *gyroStructure = [[QCStructure alloc] initWithDictionary:gyroscope];
  [output3DOrientation setStructureValue:gyroStructure];
  
  NSDictionary *acceleration = [NSDictionary dictionary];
  if ([dataDictionary objectForKey:@"acceleration"]) {
    acceleration = [dataDictionary objectForKey:@"acceleration"];
  }
  QCStructure *accelerationStructure = [[QCStructure alloc] initWithDictionary:acceleration];
  [outputAcceleration setStructureValue:accelerationStructure];
  
  NSDictionary *rotationRate = [NSDictionary dictionary];
  if ([dataDictionary objectForKey:@"rotationRate"]) {
    rotationRate = [dataDictionary objectForKey:@"rotationRate"];
  }
  QCStructure *rotationStructure = [[QCStructure alloc] initWithDictionary:rotationRate];
  [outputRotationRate setStructureValue:rotationStructure];
  
  return YES;
}

@end
