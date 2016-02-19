/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBLastValue.h"

@interface FBLastValue ()
@property NSMutableDictionary *values;
@end

@implementation FBLastValue

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8 {
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8 {
	return kQCPatchExecutionModeProvider; // Execute continuously
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8 {
	return kQCPatchTimeModeIdle;
}

- (BOOL)setup:(QCOpenGLContext *)context {
  self.values = [NSMutableDictionary dictionary];
  
  return YES;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
  NSNumber *currentIteration = @(inputIterationIndex.indexValue);
  
  // Set the output to the previous frame's saved value
  outputValue.rawValue = self.values[currentIteration];
  
  // Store the current frame's value
  if (inputValue.value)
    self.values[currentIteration] = inputValue.value;
  
  return YES;
}

@end
