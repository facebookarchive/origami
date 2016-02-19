/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOStructureCombinePatch.h"

@implementation FBOStructureCombinePatch

+ (BOOL)allowsSubpatchesWithIdentifier:(id)identifier {
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)identifier {
  return kQCPatchExecutionModeProcessor;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)identifier {
  return kQCPatchTimeModeNone;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
  QCStructure *structure1 = inputStructure1.structureValue;
  QCStructure *structure2 = inputStructure2.structureValue;
  QCStructure *outStructure;
  
  if (!inputStructure1.wasUpdated && !inputStructure2.wasUpdated) {
    return YES;
  }
  
  if (structure1) {
    outStructure = [[QCStructure alloc] initWithStructure:structure1];
    GFList *outList = [outStructure _list];
    GFList *structure2List = [structure2 _list];
    
    @try {
      [outList addEntriesFromList:structure2List];
    }
    @catch (NSException *e) {
      for (NSUInteger i = 0; i < structure2List.count; ++i)
        if ([outList indexOfKey:[structure2List keyAtIndex:i]] == NSNotFound)
          [outList addObject:[structure2List objectAtIndex:i] forKey:[structure2List keyAtIndex:i]];
        else
          [outList setObject:[structure2List objectAtIndex:i] forKey:[structure2List keyAtIndex:i]];
    }
  }
  else {
    if (structure2)
      outStructure = [[QCStructure alloc] initWithStructure:structure2];
    else
      outStructure = [[QCStructure alloc] init];
  }
  
  outputStructure.structureValue = outStructure;
  
  return YES;
}

@end
