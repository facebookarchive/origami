/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FB3DOrientationPatch.h"

@implementation FB3DOrientationPatch

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8
{
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8
{
	return kQCPatchExecutionModeProcessor;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8
{
	return kQCPatchTimeModeNone;
}

- (id)initWithIdentifier:(id)fp8
{
	if (self = [super initWithIdentifier:fp8])
		[[self userInfo] setObject:@"3D Orientation" forKey:@"name"];
  
	return self;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments
{
  [outputPitch setDoubleValue:[[[input3DOrientation structureValue] memberForKey:@"pitch"] doubleValue]];
  [outputRoll setDoubleValue:[[[input3DOrientation structureValue] memberForKey:@"roll"] doubleValue]];
  [outputYaw setDoubleValue:[[[input3DOrientation structureValue] memberForKey:@"yaw"] doubleValue]];
  
	return YES;
}


@end
