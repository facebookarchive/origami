/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBDeviceVibratePatch.h"
#import "BWDeviceInfoReceiver.h"

@implementation FBDeviceVibratePatch

- (id)initWithIdentifier:(id)identifier
{
	if (self = [super initWithIdentifier:identifier]) {
    [[BWDeviceInfoReceiver sharedReceiver] patchRequestsConnection];
  }
  
	return self;
}

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8
{
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8
{
	return kQCPatchExecutionModeConsumer;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8
{
	return kQCPatchTimeModeNone;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments
{  
  if ([[BWDeviceInfoReceiver sharedReceiver] isConnected] && [inputVibrate wasUpdated]) {
    BOOL state = [inputVibrate booleanValue];
    NSDictionary *vibState = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:state] forKey:@"state"];
    [[BWDeviceInfoReceiver sharedReceiver] sendData:vibState forFrameType:FBFrameTypeVibration];
  }
  
  return YES;
}


@end
