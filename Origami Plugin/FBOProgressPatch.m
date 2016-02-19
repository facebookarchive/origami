/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOProgressPatch.h"

static inline CGFloat FBOProgress(CGFloat value, CGFloat startValue, CGFloat endValue)
{
  return (value - startValue) / (endValue - startValue);
}

@implementation FBOProgressPatch

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
  if (!inputValue.wasUpdated && !inputStops.wasUpdated)
    return YES;
  
  NSArray *stops = [inputStops.structureValue arrayRepresentation];
  
  if (stops.count < 2) {
    outputProgress.doubleValue = 0;
    return YES;
  }
  
  double value = inputValue.doubleValue;
  double progress = 0;
  
  CGFloat firstStop = ((NSNumber *)stops[0]).floatValue;
  CGFloat lastStop = ((NSNumber *)stops[stops.count-1]).floatValue;

  if (value <= firstStop) {
    CGFloat secondStop = ((NSNumber *)stops[1]).floatValue;
    progress = FBOProgress(value, firstStop, secondStop);
  }
  else if (value >= lastStop) {
    CGFloat secondLastStop = ((NSNumber *)stops[stops.count-2]).floatValue;
    progress = FBOProgress(value, secondLastStop, lastStop) + (stops.count - 2);
  }
  else {
    for (int i = 0; i < stops.count - 1; i++) {
      CGFloat currentStop = ((NSNumber *)stops[i]).floatValue;
      CGFloat nextStop = ((NSNumber *)stops[i+1]).floatValue;

      if ((value > currentStop && value < nextStop) || value == currentStop) {
        progress = FBOProgress(value, currentStop, nextStop) + i;
        break;
      }
    }
  }
  
  outputProgress.doubleValue = progress;
  
  return YES;
}


@end
