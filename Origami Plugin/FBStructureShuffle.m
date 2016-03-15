/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBStructureShuffle.h"

@implementation FBStructureShuffle

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

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
  BOOL leadingEdge = [inputShuffleSignal wasUpdated] && [inputShuffleSignal booleanValue] == YES;
  
  if (leadingEdge || [inputStructure wasUpdated]) {
    NSArray *array = [[inputStructure structureValue] arrayRepresentation];
    
    NSMutableArray *mutableArray = [array mutableCopy];
    
    for (NSUInteger i = array.count; i > 1; i--) {
      NSUInteger j = arc4random_uniform(i);
      [mutableArray exchangeObjectAtIndex:i-1 withObjectAtIndex:j];
    }
    
    [outputStructure setStructureValue:[[QCStructure alloc] initWithArray:mutableArray]];
  }
  
  return YES;
}

@end
