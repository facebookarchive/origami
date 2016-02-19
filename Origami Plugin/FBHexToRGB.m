/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBHexToRGB.h"

@implementation FBHexToRGB

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
  if (inputHex.wasUpdated) {
    NSString *hexString = inputHex.stringValue;
    
    // Remove the hash if one exists
    if ([hexString hasPrefix:@"#"]) {
      hexString = [hexString substringFromIndex:1];
    }
    
    // Support three character Hex values. E.g, #123 should equal #112233.
    if (hexString.length == 3) {
      NSString *char1 = [hexString substringWithRange:NSMakeRange(0, 1)];
      NSString *char2 = [hexString substringWithRange:NSMakeRange(1, 1)];
      NSString *char3 = [hexString substringWithRange:NSMakeRange(2, 1)];
      hexString = [NSString stringWithFormat:@"%@%@%@%@%@%@",char1,char1,char2,char2,char3,char3];
    }
    
    // Convert to RGB
    unsigned int colorInt = 0;
    [[NSScanner scannerWithString:hexString] scanHexInt:&colorInt];
    
    CGFloat red = ((colorInt & 0xFF0000) >> 16) / 255.0;
    CGFloat green = ((colorInt & 0x00FF00) >> 8) / 255.0;
    CGFloat blue = (colorInt & 0x0000FF) / 255.0;

    [outputRed setDoubleValue:red];
    [outputGreen setDoubleValue:green];
    [outputBlue setDoubleValue:blue];
  }
  
  return YES;
}

@end
