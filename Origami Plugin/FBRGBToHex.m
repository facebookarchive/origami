/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBRGBToHex.h"

@implementation FBRGBToHex

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8 {
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8 {
	return kQCPatchExecutionModeProcessor;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8 {
	return kQCPatchTimeModeNone;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
  if (inputRed.wasUpdated || inputGreen.wasUpdated || inputBlue.wasUpdated) {
    NSString *hexString = [NSString stringWithFormat:@"%02X%02X%02X", (int)(inputRed.doubleValue * 255), (int)(inputGreen.doubleValue * 255), (int)(inputBlue.doubleValue * 255)];
    [outputHex setStringValue:hexString];
  }
  
  return YES;
}

@end
