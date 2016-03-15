/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <Foundation/Foundation.h>

@interface NSString (FBAdditions)

- (BOOL)fb_containsString:(NSString *)string;
- (NSString *)fb_capitalizeFirstLetter;
- (NSString *)relativePathFromBaseDirPath:(NSString *)baseDirPath;
- (NSArray *)componentsSeparatedByUnescapedDelimeter:(NSString *)delimeter;
- (NSArray *)componentsSeparatedByUnescapedDelimeters:(NSArray *)delimeters map:(NSArray **)delimeterMap;
- (NSString *)humanReadableString;

@end
