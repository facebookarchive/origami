/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "NSAppleScript+FBAdditions.h"
#import "NSAppleEventDescriptor+FBAdditions.h"

@implementation NSAppleScript (FBAdditions)

+ (id)runScript:(NSString *)script {
  NSString *error = nil;
  id result = [NSAppleScript runScript:script error:&error];
  if (error) {
    NSLog(@"AppleScript Error: %@", error.description);
    return nil;
  }
  return result;
}

+ (id)runScript:(NSString *)script error:(NSString **)error {
  NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
  
  NSDictionary *errors = nil;
  NSAppleEventDescriptor *eventDescriptor = [appleScript executeAndReturnError:&errors];
  
  if (errors) {
    if (error) {
      *error = errors.description;
    }
    return nil;
  }
  
  return eventDescriptor.objectValue;
}

+ (id)runScript:(NSString *)script inApplication:(NSString *)applicationName {
  return [NSAppleScript runScript:[NSString stringWithFormat:@"tell application \"%@\" to %@", applicationName, script]];
}

@end
