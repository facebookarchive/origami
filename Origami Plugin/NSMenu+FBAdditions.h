/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <Cocoa/Cocoa.h>

@interface NSMenu (FBAdditions)
- (NSMenuItem *)addItemWithTitle:(NSString *)title keyEquivalent:(NSString *)keyEquivalent target:(id)target action:(SEL)action state:(BOOL)state;
@end
