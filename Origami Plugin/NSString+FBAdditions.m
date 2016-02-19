/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "NSString+FBAdditions.h"

@implementation NSString (FBAdditions)

- (BOOL)fb_containsString:(NSString *)string {
  return [self rangeOfString:string].location != NSNotFound;
}

- (NSString *)fb_capitalizeFirstLetter {
  NSString *firstCharacter = [self substringToIndex:1];
  return [[firstCharacter uppercaseString] stringByAppendingString:[self substringFromIndex:1]];
}

- (NSString *)relativePathFromBaseDirPath:(NSString *)baseDirPath {
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
