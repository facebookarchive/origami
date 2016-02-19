/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBStopWatchPatch.h"

@interface FBStopWatchPatch ()
@property NSMutableDictionary *timeCounts;
@property NSMutableDictionary *frameCounts;
@property NSMutableDictionary *previousFrameTimes;
@property NSMutableDictionary *previousFrameOns;
@property NSMutableDictionary *previousFrameResetSignals;
@property NSUInteger iterationCount;
@property double previousTime;
@end

@implementation FBStopWatchPatch

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8 {
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8 {
	return kQCPatchExecutionModeProcessor;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8 {
	return kQCPatchTimeModeTimeBase;
}

- (BOOL)setup:(QCOpenGLContext *)context {
  self.timeCounts = [NSMutableDictionary dictionary];
  self.frameCounts = [NSMutableDictionary dictionary];
  self.previousFrameTimes = [NSMutableDictionary dictionary];
  self.previousFrameOns = [NSMutableDictionary dictionary];
  self.previousFrameResetSignals = [NSMutableDictionary dictionary];
  
  return [super setup:context];
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
  BOOL frameDidStart = (time != self.previousTime);
  self.previousTime = time;
  self.iterationCount = frameDidStart ? 0 : self.iterationCount + 1;

  NSNumber *iterationKey = @(self.iterationCount);
  
  NSUInteger frameCount = ((NSNumber *)self.frameCounts[iterationKey]).unsignedIntegerValue;
  double timeCount = ((NSNumber *)self.timeCounts[iterationKey]).doubleValue;
  BOOL previousFrameResetSignal = ((NSNumber *)self.previousFrameResetSignals[iterationKey]).boolValue;
  BOOL previousFrameOn = ((NSNumber *)self.previousFrameOns[iterationKey]).boolValue;
  double previousFrameTime = ((NSNumber *)self.previousFrameTimes[iterationKey]).doubleValue;
  
  BOOL resetSignalWasUpdated = (inputResetSignal.booleanValue != previousFrameResetSignal);
  BOOL onWasUpdated = (inputOn.booleanValue != previousFrameOn);
  
  BOOL shouldReset = (inputResetSignal.booleanValue && resetSignalWasUpdated);
  
  if ((inputOn.booleanValue && !onWasUpdated) || shouldReset) {
    frameCount = shouldReset ? 0 : frameCount + 1;
    timeCount = shouldReset ? 0 : (timeCount + (time - previousFrameTime));
    
    self.frameCounts[iterationKey] = @(frameCount);
    self.timeCounts[iterationKey] = @(timeCount);
  }
    
  outputFrames.indexValue = frameCount;
  outputTime.doubleValue = timeCount;
  
  self.previousFrameOns[iterationKey] = @(inputOn.booleanValue);
  self.previousFrameResetSignals[iterationKey] = @(inputResetSignal.booleanValue);
  self.previousFrameTimes[iterationKey] = @(time);
    
  return YES;
}

@end
