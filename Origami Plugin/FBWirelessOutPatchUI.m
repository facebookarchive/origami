/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBWirelessOutPatchUI.h"
#import "FBWirelessOutPatch.h"
#import "FBWirelessController.h"
#import "QCPatch+FBAdditions.h"

@implementation FBWirelessOutPatchUI

+ (NSString *)viewNibName
{
  return @"FBWirelessOutPatchUI";
}

+ (NSString *)viewTitle
{
  return @"Settings";
}

- (void)setupViewForPatch:(FBWirelessOutPatch *)thePatch {
  [self.popUpButton removeAllItems];
  
  NSMutableArray *sortedTitles = [NSMutableArray arrayWithArray:thePatch.controller.keyedData.allKeys];
  [sortedTitles sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
  
  [self.popUpButton addItemsWithTitles:sortedTitles];
  
  if (thePatch.selectedKey) {
    [self.popUpButton selectItemWithTitle:thePatch.selectedKey];
  }
  
  QCPatch *broadcaster = thePatch.controller.keyedBroadcasters[thePatch.selectedKey];
  self.broadcastButton.enabled = (broadcaster != nil);
  
  [super setupViewForPatch:thePatch];
}

- (IBAction)popUpSelectionChanged:(NSPopUpButton *)button {
  FBWirelessOutPatch *thePatch = (FBWirelessOutPatch *)self.patch;
  [thePatch setSelectedKey:[button titleOfSelectedItem]];
}

- (IBAction)viewBroadcaster:(NSButton *)button {
  FBWirelessOutPatch *thePatch = (FBWirelessOutPatch *)self.patch;
  QCPatch *broadcaster = thePatch.controller.keyedBroadcasters[thePatch.selectedKey];

  if (broadcaster) {
    NSDocument *document = [thePatch fb_document];

    if ([document respondsToSelector:@selector(editorController)]) {
      id editorController = [document performSelector:@selector(editorController)];
      
      if ([editorController respondsToSelector:@selector(editingView)]) {
        QCPatchEditorView *editorView = (QCPatchEditorView *)[editorController performSelector:@selector(editingView)];
        
        if ([broadcaster parentPatch]) {
          [editorView setGraph:[broadcaster parentPatch]];
          
          NSValue *positionValue = [[broadcaster userInfo] objectForKey:@"position"];
          NSPoint position = positionValue.pointValue;
          
          [editorView setEditorCenter:position];
        }
      }
    }
  }
}

@end
