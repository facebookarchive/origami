/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <Cocoa/Cocoa.h>
@class FBSafariSegmentedCell;

@interface FBSafariToolbarController : NSViewController

@property (unsafe_unretained) IBOutlet NSToolbar *toolbar;
@property (unsafe_unretained) IBOutlet NSTextField *textField;
@property (unsafe_unretained) IBOutlet NSButton *downloadsButton;
@property (unsafe_unretained) IBOutlet NSSegmentedControl *backForwardButtons;
@property (unsafe_unretained) IBOutlet FBSafariSegmentedCell *segmentedCell;
@property (strong, nonatomic) NSImageView *faviconView;
@property (strong, nonatomic) NSImage *faviconImage;
@property (copy, nonatomic) NSString *URL;
@property BOOL forwardDown;
@property BOOL backDown;
@property (weak) IBOutlet NSToolbarItem *segmentedItem;
@property (weak) IBOutlet NSToolbarItem *rightButtonItem;
@property BOOL isYosemiteOrGreater;

- (void)setFaviconGraphic:(NSImage *)image;
- (void)setURLLabel:(NSString *)label;
+ (FBSafariToolbarController *)controllerForQCView:(QCView *)view;

@end
