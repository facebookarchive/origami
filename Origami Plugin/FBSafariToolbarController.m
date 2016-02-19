/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBSafariToolbarController.h"
#import "FBSafariSegmentedCell.h"

@implementation FBSafariToolbarController

static NSMutableDictionary *controllers; // Key: QCView pointer address  Value: FBSafariToolbarController instance

+ (FBSafariToolbarController *)controllerForQCView:(QCView *)view {
  if (view == nil) {
    return nil;
  }
  
  NSString *pointerAddress = [NSString stringWithFormat:@"%p", view];
  FBSafariToolbarController *controller;

  if (!controllers) {
    controllers = [[NSMutableDictionary alloc] init];
  }
  
  if ([controllers objectForKey:pointerAddress]) {
    controller = [controllers objectForKey:pointerAddress];
  } else {
    FBSafariToolbarController *newController = [[FBSafariToolbarController alloc] initWithNibName:@"FBSafariToolbarController" bundle:[NSBundle bundleForClass:[self class]]];
    [controllers setObject:newController forKey:pointerAddress];
    controller = newController;
  }

  return controller;
}

- (void)loadView {
  [super loadView];
  
  self.isYosemiteOrGreater = [self.view.window respondsToSelector:@selector(setTitleVisibility:)];
  
  self.segmentedCell.toolbarController = self;
  
  self.faviconView = [[NSImageView alloc] initWithFrame:NSMakeRect(5, 3, 16, 16)];
  
  if (!self.isYosemiteOrGreater) {
    [self.textField addSubview:self.faviconView];
  }

  self.faviconView.image = self.faviconImage;
  
  self.textField.stringValue = self.URL;
  
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  NSString *refreshIconName = self.isYosemiteOrGreater ? @"RefreshIconYosemite" : @"RefreshIcon";
  NSImage *refreshImage = [[NSImage alloc] initByReferencingFile:[bundle pathForImageResource:refreshIconName]];
  NSImageView *refreshIcon = [[NSImageView alloc] initWithFrame:NSMakeRect(self.textField.bounds.size.width - refreshImage.size.width - 5, 3, refreshImage.size.width, refreshImage.size.height)];
  refreshIcon.autoresizingMask = NSViewMinXMargin;
  refreshIcon.image = refreshImage;
  [self.textField addSubview:refreshIcon];
  
  if ([self.view.window respondsToSelector:@selector(setTitleVisibility:)])
    [self adjustForYosemite];
}

- (void)adjustForYosemite {
  self.backForwardButtons.segmentStyle = NSSegmentStyleSeparated;
  
  // Make the segmented control a bit wider
  NSSize maxSize = self.segmentedItem.maxSize;
  maxSize.width += 4;
  self.segmentedItem.maxSize = maxSize;
  
  CGFloat width = [self.backForwardButtons widthForSegment:0];
  CGFloat newWidth = width + 2;
  [self.backForwardButtons setWidth:newWidth forSegment:0];
  [self.backForwardButtons setWidth:newWidth forSegment:1];
  
  // Make the downloads button wider
  maxSize = self.rightButtonItem.maxSize;
  maxSize.width += 9;
  self.rightButtonItem.maxSize = maxSize;
  
  // Add some spacers
  [self.toolbar insertItemWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier atIndex:1];
  [self.toolbar insertItemWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier atIndex:1];
  [self.toolbar insertItemWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier atIndex:4];
  [self.toolbar insertItemWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier atIndex:4];
  [self.toolbar insertItemWithItemIdentifier:NSToolbarSpaceItemIdentifier atIndex:6];
  [self.toolbar insertItemWithItemIdentifier:NSToolbarSpaceItemIdentifier atIndex:6];
  
  self.textField.alignment = NSCenterTextAlignment;
  
  // Get default white space out of there
  NSString *trimmedText = [self.textField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  self.textField.stringValue = trimmedText;
  
  // Replace the downloads icon with a tab icon
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  NSImage *tabsIcon = [[NSImage alloc] initByReferencingFile:[bundle pathForImageResource:@"TabsIcon"]];
  self.downloadsButton.image = tabsIcon;
  ((NSButtonCell *)self.downloadsButton.cell).highlightsBy = NSChangeBackgroundCellMask;
}

- (void)setFaviconGraphic:(NSImage *)image {
  self.faviconImage = image;
  self.faviconView.image = image;
}

- (void)setURLLabel:(NSString *)label {
  if (!self.isYosemiteOrGreater) {
    // Add padding to account for the favicon
    label = [@"      " stringByAppendingString:label];
  }
  
  self.URL = label;
  self.textField.stringValue = label;
}

@end
