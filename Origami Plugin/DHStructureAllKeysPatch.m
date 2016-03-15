/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "DHStructureAllKeysPatch.h"
#import "NSArray+FBAdditions.h"

@implementation DHStructureAllKeysPatch

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)identifier {
	return kQCPatchExecutionModeProcessor;
}

+ (BOOL)allowsSubpatchesWithIdentifier:(id)identifier {
	return NO;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)identifier {
	return kQCPatchTimeModeNone;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
    if (!(inputStructure.wasUpdated || inputSort.wasUpdated)) {
        return YES;
    }
    
    NSArray *allKeys = [[inputStructure.structureValue dictionaryRepresentation] allKeys];
    
    if (inputSort.booleanValue) {
        allKeys = [allKeys sortedArrayUsingAlphabeticalSort];
    }
    
    outputStructure.structureValue = [[QCStructure alloc] initWithArray:allKeys];
    
    return YES;
}

@end
