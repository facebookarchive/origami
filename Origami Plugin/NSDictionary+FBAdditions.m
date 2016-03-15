/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "NSDictionary+FBAdditions.h"
#import "NSArray+FBAdditions.h"
#import "NSString+FBAdditions.h"

@implementation NSDictionary (FBAdditions)

- (id)valueAtPath:(NSArray *)path {
    return [self valueAtPath:path untraversedPaths:nil];
}

- (id)valueAtPath:(NSArray *)path untraversedPaths:(NSArray **)untraversedPaths {
    NSDictionary *dictionary = self;
    BOOL _debug = NO;
    
    if (_debug) NSLog(@"_objectAtPath:(%@) inDictionary:(%@)", path, dictionary);
    if (![path count] || ![dictionary count]) {
        return nil;
    }
    
    // The function is recursive so we examine only the first component every time
    NSMutableString *nextPathComponent = [[path objectAtIndex:0] mutableCopy];
    BOOL wildcard = ([nextPathComponent isEqualToString:@"*"]);
    NSNumber *numericalKey = nil;
    
    // Check to see if the key value is an index number
    NSUInteger numericalIndexForKey = NSNotFound;
    if ([nextPathComponent isEqualToString:[[NSNumber numberWithInteger:[nextPathComponent integerValue]] stringValue]]) {
        numericalIndexForKey = [nextPathComponent integerValue];
    } else if ([nextPathComponent hasPrefix:@"["] && [nextPathComponent hasSuffix:@"]"] && [nextPathComponent length] >= 3) {
        numericalIndexForKey = [[nextPathComponent substringWithRange:NSMakeRange(1, nextPathComponent.length - 2)] integerValue];
    }
    if (numericalIndexForKey != NSNotFound && numericalIndexForKey < [dictionary count]) {
        NSArray *sortedKeys = [[dictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
        
        id keyForNumericalIndex = [sortedKeys objectAtIndex:numericalIndexForKey];
        if ([keyForNumericalIndex isKindOfClass:[NSString class]]) {
            [nextPathComponent setString:keyForNumericalIndex];
        } else if ([keyForNumericalIndex isKindOfClass:[NSNumber class]]) {
            nextPathComponent = nil;
            numericalKey = keyForNumericalIndex;
        }
    }
    
    if (nextPathComponent) {
        [nextPathComponent replaceOccurrencesOfString:@"\\[" withString:@"[" options:0 range:NSMakeRange(0, nextPathComponent.length)];
        [nextPathComponent replaceOccurrencesOfString:@"\\\\" withString:@"\\" options:0 range:NSMakeRange(0, nextPathComponent.length)];
    }
    
    NSArray *keysSpecified = [nextPathComponent componentsSeparatedByUnescapedDelimeter:@"+"];
    
    // If there's a wildcard, investigate every branch; otherwise take the specified component key(s)
    NSArray *keysToTraverse;
    if (wildcard) {
        keysToTraverse = [dictionary allKeys];
    } else if (nextPathComponent) {
        keysToTraverse = keysSpecified;
    } else if (numericalKey) {
        keysToTraverse = @[numericalKey];
    }
    if (_debug) NSLog(@"keysToTraverse = %@", keysToTraverse);
    
    // For index-based keys, sort them numerically
    BOOL allKeysAreNumbers = YES;
    for (id key in keysToTraverse) {
        if (![key isKindOfClass:[NSNumber class]]) {
            allKeysAreNumbers = NO;
            break;
        }
    }
    if (allKeysAreNumbers) {
        keysToTraverse = [keysToTraverse sortedArrayUsingAlphabeticalSort];
    }
    
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:[keysToTraverse count]];
    NSMutableArray *resultingUntraversedPaths = [NSMutableArray arrayWithCapacity:[path count]];
    
    // For the non-wildcard case, this loop will only execute once
    for (id key in keysToTraverse) {
        id object = [dictionary objectForKey:key];
        
        NSMutableArray *pathsToTraverseOnBranch = [path mutableCopy];
        if ([path count]) {
            [pathsToTraverseOnBranch removeObjectAtIndex:0];
        }
        
        // Start with the assumption that we find a value
        NSArray *untraversedPathsOnBranch = pathsToTraverseOnBranch;
        
        // If we encounter a dictionary result and still have work to do, invoke the recursive procuedure
        if ([object isKindOfClass:[NSDictionary class]] && [pathsToTraverseOnBranch count]) {
            object = [object valueAtPath:pathsToTraverseOnBranch untraversedPaths:&untraversedPathsOnBranch];
        }
        
        if (_debug) NSLog(@"object = %@ for key %@", object, key);
        if (object) {
            // Collect the result
            [results addObject:object];
        } else {
            // No value: revert the earlier assumption
            [results addObject:[NSNull null]];
            untraversedPathsOnBranch = [[NSArray arrayWithObject:nextPathComponent] arrayByAddingObjectsFromArray:untraversedPathsOnBranch];
        }
        
        if (untraversedPathsOnBranch) {
            // Collect the untraversed path result, which may have been replaced by the recursion
            if (_debug) NSLog(@"Untraversed: %@", untraversedPathsOnBranch);
            [resultingUntraversedPaths addObject:untraversedPathsOnBranch];
        }
    }
    
    // Flatten results and paths if necessary
    if ([results count] == 1) {
        results = [results objectAtIndex:0];
    }
    if ([resultingUntraversedPaths count] == 1) {
        [resultingUntraversedPaths setArray:[resultingUntraversedPaths objectAtIndex:0]];
    }
    
    // Resolve a remaining untraversed index on the entire result set, if possible
    if ([results isKindOfClass:[NSArray class]] && [results count] > 1 && [resultingUntraversedPaths count] == 1) {
        id untraversedComponent = [resultingUntraversedPaths lastObject];
        NSUInteger untraversedIndex = [untraversedComponent integerValue];
        if ([untraversedComponent isEqualToString:[[NSNumber numberWithInteger:untraversedIndex] stringValue]]) {
            [results setArray:[NSArray arrayWithObject:[results objectAtIndex:untraversedIndex]]];
        }
    }
    
    // If all of our child paths are identical or empty, flatten the result as a single array
    BOOL untraversedPathsAreAllIdentical = YES;
    BOOL virginity = YES;
    id candidateForTestingIdenticalness = nil;
    for (id branchPath in resultingUntraversedPaths) {
        if (virginity) {
            candidateForTestingIdenticalness = branchPath;
            virginity = NO;
            continue;
        }
        if (![branchPath isEqual:candidateForTestingIdenticalness]) {
            untraversedPathsAreAllIdentical = NO;
            break;
        }
    }
    if (untraversedPathsAreAllIdentical) {
        if (candidateForTestingIdenticalness && ![candidateForTestingIdenticalness isKindOfClass:[NSArray class]]) {
            candidateForTestingIdenticalness = @[candidateForTestingIdenticalness];
        }
        if (candidateForTestingIdenticalness && [candidateForTestingIdenticalness count]) {
            [resultingUntraversedPaths setArray:candidateForTestingIdenticalness];
        } else {
            [resultingUntraversedPaths removeAllObjects];
        }
    }
    
    // Pass discovered untraversed paths back to the calling function
    if (_debug) NSLog(@"Resulting untraversed: %@", resultingUntraversedPaths);
    if (untraversedPaths) {
        *untraversedPaths = resultingUntraversedPaths;
    }
    
    if ([keysToTraverse count] == 1) {
        return results;
    }
    
    if (allKeysAreNumbers) {
        return results;
    }
    
    // Maintain the original keys when possible
    NSUInteger resultIndex;
    NSMutableDictionary *dictionaryResult = [NSMutableDictionary dictionaryWithCapacity:results.count];
    for (resultIndex = 0; resultIndex < results.count; resultIndex++) {
        [dictionaryResult setObject:results[resultIndex] forKey:keysToTraverse[resultIndex]];
    }
    return dictionaryResult;
}

- (QCStructure *)arrayOrDictionaryStructureFromDictionary {
  NSDictionary *dictionary = self;
  QCStructure *structureAsDictionary = [[QCStructure alloc] initWithDictionary:dictionary];
  
  // Check to see if the structure should be an array: if it has linear numerical keys starting at 0
  NSArray *keys = [[dictionary allKeys] sortedArrayUsingAlphabeticalSort];
  NSInteger previousKey = -1;
  NSMutableArray *values = [NSMutableArray arrayWithCapacity:keys.count];
  
  for (id key in keys) {
    if (!([key isKindOfClass:[NSNumber class]] && [key integerValue] == previousKey + 1)) {
      return structureAsDictionary;
    } else {
      [values addObject:dictionary[key]];
      previousKey++;
    }
  }
  
  // Structure is array: just return the values
  return [[QCStructure alloc] initWithArray:values];
}

@end
