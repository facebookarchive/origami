/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiAdditions+Tooltips.h"
#import "NSObject+FBAdditions.h"

@interface FBOrigamiAdditions ()
- (void)original__showTooltip;
@end

@implementation FBOrigamiAdditions (Tooltips)

- (void)setupTooltipHiding {
  // Add menu item for turning this feature on and off
  self.tooltipsHidden = [[NSUserDefaults standardUserDefaults] boolForKey:@"FBTooltipsHidden"];
  self.hideTooltipsMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Hide Tooltips" action:@selector(toggleTooltipsHidden:) keyEquivalent:@""];
  [(id)self.hideTooltipsMenuItem setTarget:self];
  self.hideTooltipsMenuItem.state = self.tooltipsHidden;
  [self.origamiMenu addItem:self.hideTooltipsMenuItem];
  
  [self fb_swizzleInstanceMethod:@selector(_showTooltip) forClassName:@"GFGraphView"];
}

- (void)_showTooltip {
  static FBOrigamiAdditions *sharedAdditions;
  if (!sharedAdditions)
    sharedAdditions = [FBOrigamiAdditions sharedAdditions];
  
  if (!sharedAdditions.tooltipsHidden) {
    [self original__showTooltip];
  }
}

- (void)toggleTooltipsHidden:(NSMenuItem *)menuItem {
  self.tooltipsHidden = !self.tooltipsHidden;
  
  [[NSUserDefaults standardUserDefaults] setBool:self.tooltipsHidden forKey:@"FBTooltipsHidden"];
  
  self.hideTooltipsMenuItem.state = self.tooltipsHidden;
}

@end
