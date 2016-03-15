/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "NSDate+FBAdditions.h"

@implementation NSDate (FBAdditions)

+ (NSDate *)dateWithEventDescriptor:(NSAppleEventDescriptor *)descriptor {
  NSDate *date = nil;
  
  CFAbsoluteTime absoluteTime;
  LongDateTime longDateTime;
  
  if ([descriptor descriptorType] == typeLongDateTime) {
    [[descriptor data] getBytes:&longDateTime length:sizeof(longDateTime)];
    OSStatus status = UCConvertLongDateTimeToCFAbsoluteTime(longDateTime, &absoluteTime);
    if (status == noErr) {
      date = (NSDate *)CFBridgingRelease(CFDateCreate(NULL, absoluteTime));
    }
  }
  
  return date;
}

- (NSString *)formattedDate:(NSString *)dateFormat {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:dateFormat];
  return [dateFormatter stringFromDate:self];
}


@end
