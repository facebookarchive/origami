/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBWirelessInPatchUI.h"
#import "FBWirelessInPatch.h"

@implementation FBWirelessInPatchUI

+ (NSString *)viewNibName
{
  return @"FBWirelessInPatchUI";
}

+ (NSString *)viewTitle
{
  return @"Settings";
}

- (void)setupViewForPatch:(FBWirelessInPatch *)thePatch {
  if ([thePatch selectedInputType]) {
    [self.popUpButton selectItemWithTitle:[thePatch selectedInputType]];
  }
  
  [super setupViewForPatch:thePatch];
}

- (IBAction)popUpSelectionChanged:(NSPopUpButton *)button {
  FBWirelessInPatch *thePatch = (FBWirelessInPatch *)self.patch;
  [thePatch setSelectedInputType:[button titleOfSelectedItem]];
}

@end
