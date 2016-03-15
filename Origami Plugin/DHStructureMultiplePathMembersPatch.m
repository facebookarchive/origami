/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "DHStructureMultiplePathMembersPatch.h"
#import "DHStructurePathMemberPatch.h"
#import "NSString+FBAdditions.h"

@implementation DHStructureMultiplePathMembersPatch : QCPatch

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
    if (!(inputStructure.wasUpdated || inputPaths.wasUpdated)) {
        return YES;
    }
    
    NSDictionary *dictionary = [inputStructure.structureValue dictionaryRepresentation];
    NSString *searchPaths = inputPaths.stringValue;
    NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
    
    NSArray *paths = [searchPaths componentsSeparatedByUnescapedDelimeter:@","];
    for (NSString *path in paths) {
        NSArray *keyAndValue = [path componentsSeparatedByUnescapedDelimeter:@"="];
        if (![keyAndValue count]) {
            continue;
        }
        
        NSString *key = [keyAndValue[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *value = [[keyAndValue lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSArray *keyComponents = [key componentsSeparatedByUnescapedDelimeter:@"/"];
        
        id result = [DHStructurePathMemberPatch memberForPath:value inDictionary:dictionary untraversedPaths:NULL];
        if (result) {
            if (keyComponents.count == 1) {
                results[key] = result;
            } else {
                NSMutableDictionary *parentBucket = results;
                NSMutableDictionary *bucket;
                NSUInteger componentIndex;
                
                for (componentIndex = 0; componentIndex < (keyComponents.count - 1); componentIndex++) {
                    bucket = parentBucket[keyComponents[componentIndex]];
                    if (bucket) {
                        bucket = [bucket mutableCopy];
                    } else {
                        bucket = [[NSMutableDictionary alloc] init];
                    }
                    parentBucket[keyComponents[componentIndex]] = bucket;
                    parentBucket = bucket;
                }
                
                bucket[keyComponents.lastObject] = result;
            }
        }
    }
    
    if (results && [results count]) {
        outputStructure.structureValue = [[QCStructure alloc] initWithDictionary:results];
    } else {
        outputStructure.structureValue = nil;
    }
    
    return YES;
}


@end
