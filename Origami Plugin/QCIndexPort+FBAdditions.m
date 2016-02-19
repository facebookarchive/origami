/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "QCIndexPort+FBAdditions.h"

@implementation QCIndexPort (FBAdditions)

- (NSArray *)fb_menuByRemovingSeparators {
  if (!self.attributes[@"menu"])
    return nil;
  
  NSMutableArray *mutableMenu = [NSMutableArray array];
  
  for (NSString *menuItem in self.attributes[@"menu"]) {
    if (![menuItem isEqualToString:@"-"]) {
      [mutableMenu addObject:menuItem];
    }
  }
  
  return [NSArray arrayWithArray:mutableMenu];
}

- (NSString *)fb_menuTitleValue {
  NSArray *menu = [self fb_menuByRemovingSeparators];
  
  if (self.indexValue < menu.count)
    return [menu objectAtIndex:self.indexValue];
  
  return nil;
}

@end
