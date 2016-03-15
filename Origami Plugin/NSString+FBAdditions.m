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

- (NSArray *)componentsSeparatedByUnescapedDelimeter:(NSString *)delimeter {
  return [self componentsSeparatedByUnescapedDelimeters:@[delimeter] map:NULL];
}

- (NSArray *)componentsSeparatedByUnescapedDelimeters:(NSArray *)delimeters map:(NSArray **)delimeterMap {
  BOOL _debug = NO;
  
  if (!(delimeters && [delimeters count])) {
    return nil;
  }
  
  static NSString *escape = @"\\";
  static NSString *doubleEscape = @"\\\\";
  
  NSMutableArray *components = [NSMutableArray array];
  NSMutableArray *map = [NSMutableArray array];
  
  NSScanner *inputScanner = [NSScanner scannerWithString:self];
  [inputScanner setCharactersToBeSkipped:nil];
  
  NSString *previousDelimeter = nil;
  
  while (![inputScanner isAtEnd]) {
    NSString *candidate = nil, *previousCandidate = nil, *delimeter = nil;
    
    do {
      previousCandidate = candidate;
      
      NSString *stringToBeScanned = [[inputScanner string] substringFromIndex:[inputScanner scanLocation]];
      if (_debug) NSLog(@"stringToBeScanned: %@", stringToBeScanned);
      NSUInteger firstOccuringLocation = NSNotFound;
      NSString *firstOccuringDelimeter = nil;
      for (NSString *delimeterCandidate in delimeters) {
        NSUInteger delimeterCandidateLocation = [stringToBeScanned rangeOfString:delimeterCandidate].location;
        if ((delimeterCandidateLocation != NSNotFound) &&
            (firstOccuringLocation == NSNotFound || delimeterCandidateLocation < firstOccuringLocation)) {
          firstOccuringLocation = delimeterCandidateLocation;
          firstOccuringDelimeter = delimeterCandidate;
          if (_debug) NSLog(@"firstOccuringDelimeter: %@", firstOccuringDelimeter);
          break;
        }
      }
      delimeter = firstOccuringDelimeter;
      if (!delimeter) {
        [inputScanner scanString:stringToBeScanned intoString:&candidate];
        delimeter = [delimeters objectAtIndex:0];
        break;
      }
      
      [inputScanner scanUpToString:delimeter intoString:&candidate];
      [inputScanner scanString:delimeter intoString:NULL];
      
      if (previousCandidate && candidate) {
        candidate = [NSString stringWithFormat:@"%@%@%@", previousCandidate, delimeter, candidate];
        if (_debug) NSLog(@"candidate: %@", candidate);
      }
    } while ([candidate hasSuffix:escape] && ![candidate hasSuffix:doubleEscape] && ![inputScanner isAtEnd]);
    
    if (candidate) {
      if (_debug) NSLog(@"done. canddiate: %@", candidate);
      candidate = [candidate stringByReplacingOccurrencesOfString:doubleEscape withString:escape];
      for (NSString *delimeterToEscape in delimeters) {
        NSString *delimeterEscape = [escape stringByAppendingString:delimeterToEscape];
        candidate = [candidate stringByReplacingOccurrencesOfString:delimeterEscape withString:delimeterToEscape];
      }
      [components addObject:candidate];
      if (_debug) NSLog(@"components: %@", components);
    } else {
      [components addObject:@""];
    }
    
    if (delimeter && [delimeter isEqualToString:previousDelimeter]) {
      [map addObject:delimeter];
      previousDelimeter = nil;
    } else {
      [map addObject:@""];
      previousDelimeter = delimeter;
    }
  }
  
  if (delimeterMap) {
    *delimeterMap = map;
  }
  
  return components;
}

- (NSString *)humanReadableString {
  NSMutableString *key = [[self capitalizedString] mutableCopy];
  [key replaceOccurrencesOfString:@"_" withString:@" " options:0 range:NSMakeRange(0, key.length)];
  
  NSArray *exceptions = [NSArray arrayWithObjects:
                         @"an", @"and", @"at", @"but", @"for", @"from", @"in", @"of", @"or", @"to", @"with", @"within", @"without",
                         @"AT&T", @"HTTP", @"HTTPS", @"ID", @"IP", @"IDEO", @"UFO", @"URI", @"URL", @"URLs", @"VPN", @"WAN",
                         @"eBay", @"eMac", @"eMate", @"iCal", @"iMac", @"iPad", @"iPhone", @"iPod", @"iTunes", @"iWork", @"QuickTime", nil];
  
  for (NSString *exception in exceptions) {
    NSRange previousExceptionRange = NSMakeRange(NSNotFound, 0);
    NSRange searchRange = NSMakeRange(0, [key length]);
    
    while (YES) {
      NSRange foundExceptionRange = [key rangeOfString:exception options:NSCaseInsensitiveSearch range:searchRange];
      if (foundExceptionRange.location == NSNotFound || NSEqualRanges(foundExceptionRange, previousExceptionRange)) {
        break;
      }
      
      BOOL lowercasedException = ([exception isEqualToString:[exception lowercaseString]]);
      
      // Only perform the replacement for lowercased exceptions past the first character
      if (!lowercasedException || foundExceptionRange.location > 0) {
        NSInteger precedingCharacterIndex = (foundExceptionRange.location - 1);
        NSInteger subsequentCharacterIndex = (foundExceptionRange.location + foundExceptionRange.length);
        if ((precedingCharacterIndex < 0 || [key characterAtIndex:precedingCharacterIndex] == ' ') &&
            ([key length] <= subsequentCharacterIndex || [key characterAtIndex:subsequentCharacterIndex] == ' ')) {
          [key replaceCharactersInRange:foundExceptionRange withString:exception];
        }
      }
      
      previousExceptionRange = foundExceptionRange;
      searchRange.location = foundExceptionRange.location + 1;
      searchRange.length = [key length] - searchRange.location;
      if (searchRange.location >= [key length]) {
        break;
      }
    }
  }
  
  if ([key hasPrefix:@"Http://"] || [key hasPrefix:@"Https://"]) {
    [key setString:[key lowercaseString]];
  }
  
  return [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
