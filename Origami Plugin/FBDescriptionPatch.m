/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBDescriptionPatch.h"

@implementation FBDescriptionPatch

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8 {
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8 {
	return kQCPatchExecutionModeProcessor;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8 {
	return kQCPatchTimeModeNone;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments
{
  if (inputObject.wasUpdated == NO) {
    return YES;
  }
  
  id theObject = [inputObject rawValue];
  
  if ([theObject respondsToSelector:@selector(description)]) {
    if ([theObject respondsToSelector:@selector(dictionaryRepresentation)]) {
      theObject = [theObject dictionaryRepresentation];
    }
    
    NSString *description = [theObject description];
    [outputDescription setStringValue:description];
  }

  return YES;
}

@end
