//
//  NSString+RelativePath.m
//
//  Created by numata on 2010/01/12.
//  Copyright 2010 Satoshi Numata. All rights reserved.
//

#import "NSString+RelativePath.h"


@implementation NSString (RelativePath)

- (NSString *)absolutePathFromBaseDirPath:(NSString *)baseDirPath
{
    if ([self hasPrefix:@"~"]) {
        return [self stringByExpandingTildeInPath];
    }
    
    NSString *theBasePath = [baseDirPath stringByExpandingTildeInPath];

    if (![self hasPrefix:@"."]) {
        return [theBasePath stringByAppendingPathComponent:self];
    }
    
    NSMutableArray *pathComponents1 = [NSMutableArray arrayWithArray:[self pathComponents]];
    NSMutableArray *pathComponents2 = [NSMutableArray arrayWithArray:[theBasePath pathComponents]];

    while ([pathComponents1 count] > 0) {        
        NSString *topComponent1 = [pathComponents1 objectAtIndex:0];
        [pathComponents1 removeObjectAtIndex:0];

        if ([topComponent1 isEqualToString:@".."]) {
            if ([pathComponents2 count] == 1) {
                // Error
                return nil;
            }
            [pathComponents2 removeLastObject];
        } else if ([topComponent1 isEqualToString:@"."]) {
            // Do nothing
        } else {
            [pathComponents2 addObject:topComponent1];
        }
    }
    
    return [NSString pathWithComponents:pathComponents2];
}

- (NSString *)relativePathFromBaseDirPath:(NSString *)baseDirPath
{
    NSString *thePath = [self stringByExpandingTildeInPath];
    NSString *theBasePath = [baseDirPath stringByExpandingTildeInPath];
    
    NSMutableArray *pathComponents1 = [NSMutableArray arrayWithArray:[thePath pathComponents]];
    NSMutableArray *pathComponents2 = [NSMutableArray arrayWithArray:[theBasePath pathComponents]];

    // Remove same path components
    while ([pathComponents1 count] > 0 && [pathComponents2 count] > 0) {
        NSString *topComponent1 = [pathComponents1 objectAtIndex:0];
        NSString *topComponent2 = [pathComponents2 objectAtIndex:0];
        if (![topComponent1 isEqualToString:topComponent2]) {
            break;
        }
        [pathComponents1 removeObjectAtIndex:0];
        [pathComponents2 removeObjectAtIndex:0];
    }
    
    // Create result path
    for (int i = 0; i < [pathComponents2 count]; i++) {
        [pathComponents1 insertObject:@".." atIndex:0];
    }
    if ([pathComponents1 count] == 0) {
        return @".";
    }
    return [NSString pathWithComponents:pathComponents1];
}

@end

