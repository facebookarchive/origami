/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "DHStructureAllValuesPatch.h"
#import "NSArray+FBAdditions.h"

@implementation DHStructureAllValuesPatch

- (id)initWithIdentifier:(id)identifier {
	if (self = [super initWithIdentifier:identifier]) {
        inputSort.maxIndexValue = DHStructureSortModeCount - 1;
    }
    
	return self;
}

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
    
    NSDictionary *dictionary = [inputStructure.structureValue dictionaryRepresentation];
    NSArray *allValues = [dictionary allValues];
    
    if (inputSort.indexValue == DHStructureSortModeUsingKeys) {
        NSMutableArray *sortedValues = [[NSMutableArray alloc] initWithCapacity:[allValues count]];
        NSArray *sortedKeys = [[dictionary allKeys] sortedArrayUsingAlphabeticalSort];
        for (id key in sortedKeys) {
            id value = dictionary[key];
            if (value) {
                [sortedValues addObject:value];
            }
        }
        allValues = sortedValues;
    } else if (inputSort.indexValue == DHStructureSortModeUsingValues) {
        allValues = [allValues sortedArrayUsingAlphabeticalSort];
    }
    
    outputStructure.structureValue = [[QCStructure alloc] initWithArray:allValues];
    
    return YES;
}

@end
