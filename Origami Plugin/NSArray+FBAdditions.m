/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "NSArray+FBAdditions.h"

@implementation NSArray (FBAdditions)

id _bestRepresentationForKey(id key) {
    if ([key isKindOfClass:[NSString class]]) {
        NSNumber *numberRepresentation = [NSNumber numberWithInteger:[key integerValue]];
        if ([key isEqualToString:[numberRepresentation stringValue]]) {
            return numberRepresentation;
        }
    }
    
    return key;
}

- (NSArray *)sortedArrayUsingAlphabeticalSort {
    return [self sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        a = _bestRepresentationForKey(a);
        b = _bestRepresentationForKey(b);
        
        if ([a isKindOfClass:[NSString class]] && [b isKindOfClass:[NSString class]]) {
            return [a caseInsensitiveCompare:b];
        } else if ([a isKindOfClass:[NSNumber class]] && [b isKindOfClass:[NSNumber class]]) {
            return [a compare:b];
        } else if ([a isKindOfClass:[NSNumber class]] && [b isKindOfClass:[NSString class]]) {
            return [[a stringValue] caseInsensitiveCompare:b];
        } else if ([a isKindOfClass:[NSString class]] && [b isKindOfClass:[NSNumber class]]) {
            return [a caseInsensitiveCompare:[b stringValue]];
        } else {
            return NSOrderedSame;
        }
    }];
}

@end
