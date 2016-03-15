/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "DHStructurePathMemberPatch.h"
#import "NSDictionary+FBAdditions.h"
#import "NSString+FBAdditions.h"

@implementation DHStructurePathMemberPatch : QCPatch

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)identifier {
	return kQCPatchExecutionModeProcessor;
}

+ (BOOL)allowsSubpatchesWithIdentifier:(id)identifier {
	return NO;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)identifier {
	return kQCPatchTimeModeIdle;
}

+ (id)memberForPath:(NSString *)path inDictionary:(NSDictionary *)dictionary untraversedPaths:(NSArray **)untraversedPaths {
    NSMutableArray *pathComponents = [[path componentsSeparatedByUnescapedDelimeters:@[@"/",@"."] map:NULL] mutableCopy];
    NSUInteger emptyStringIndex = NSNotFound;
    while ((emptyStringIndex = [pathComponents indexOfObject:@""]) != NSNotFound) {
        [pathComponents removeObjectAtIndex:emptyStringIndex];
    }
    
    id result = [dictionary valueAtPath:pathComponents untraversedPaths:untraversedPaths];
    if ([result isKindOfClass:[NSArray class]] && [result count] == 1) {
        result = [result lastObject];
    }
    
    return result;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
    if (!(inputStructure.wasUpdated || inputPath.wasUpdated)) {
        return YES;
    }
    
    NSDictionary *dictionary = [inputStructure.structureValue dictionaryRepresentation];
    if (!dictionary) {
        outputUntraversedPaths.structureValue = nil;
        return YES;
    }
    
    NSArray *untraversedPaths = nil;
    NSString *path = (NSString *)inputPath.stringValue;
    if (![path length]) {
        outputMember.rawValue = inputStructure.structureValue;
        outputUntraversedPaths.structureValue = nil;
        return YES;
    }
    
    id result = [DHStructurePathMemberPatch memberForPath:path inDictionary:dictionary untraversedPaths:&untraversedPaths];
        
    if (result && [result isKindOfClass:[NSArray class]]) {
        outputMember.rawValue = [[QCStructure alloc] initWithArray:result];
    } else if (result && [result isKindOfClass:[NSDictionary class]]) {
        outputMember.rawValue = [[QCStructure alloc] initWithDictionary:result];
    } else if (result && (result != [NSNull null])) {
        outputMember.rawValue = result;
    } else {
        outputMember.rawValue = nil;
    }
    
    if (untraversedPaths) {
        outputUntraversedPaths.structureValue = [[QCStructure alloc] initWithArray:untraversedPaths];
    } else {
        outputUntraversedPaths.structureValue = nil;
    }
    
    return YES;
}

@end
