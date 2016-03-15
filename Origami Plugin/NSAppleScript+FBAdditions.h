/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <Foundation/Foundation.h>

@interface NSAppleScript (FBAdditions)
+ (NSString *)runScript:(NSString *)script;
+ (id)runScript:(NSString *)script error:(NSString **)error;
+ (NSString *)runScript:(NSString *)script inApplication:(NSString *)applicationName;
@end

static id RunAppleScript(NSString *application, NSString *script) {
  return [NSAppleScript runScript:script inApplication:application];
}
