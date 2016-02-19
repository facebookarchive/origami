/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiAdditions+WindowMods.h"
#import "GRPHookMethod.h"
#import "NSObject+AssociatedObjects.h"
#import "NSString+FBAdditions.h"
#import "FBDeviceViewController.h"
#import "FBDeviceToolbarButton.h"

static const CGFloat kEditorMenuTag = 3;
static const CGFloat kViewerMenuTag = 4;
static NSDictionary *toolbarIcons;
static NSArray *zoomIcons, *modeIcons;

@implementation FBOrigamiAdditions (WindowMods)

- (void)setupWindowMods {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeMain:) name:NSWindowDidBecomeMainNotification object:nil];
  [self addToggleStatusBarMenuItem];
  [self addTogglePathBarMenuItem];
}

- (void)didBecomeMain:(NSNotification *)notification {
  [self adjustWindows];
}

- (void)adjustWindows {
  NSArray *windows = [[NSApplication sharedApplication] windows];

  [self updateStatusBarShown];
  [self updatePathBarShown];
  
  for (NSWindow *window in windows) {
    if ([window.identifier isEqualToString:@"com.apple.QuartzComposer.editor.editor"]) {
      [self adjustEditorWindow:window];
    } else if ([window.identifier isEqualToString:@"com.apple.QuartzComposer.editor.viewer"]) {
      [self adjustViewerWindow:window];
    }
  }
}

- (void)adjustEditorWindow:(NSWindow *)window {
  for (NSView *subview in [[window contentView] subviews]) {
    if ([subview isKindOfClass:NSClassFromString(@"QCEditorPatchPathView")]) {
      NSWindow *editorWindow = window;
      NSView *splitView = nil;
      
      for (NSView *view in [[editorWindow contentView] subviews]) {
        if ([view isKindOfClass:[NSSplitView class]]) {
          splitView = view;
        }
      }
      
      NSView *editorView = [[splitView subviews] objectAtIndex:0];
      NSScrollView *scrollView = (NSScrollView *)[[editorView subviews] objectAtIndex:0];
      
      if ([scrollView borderType] != NSNoBorder) {
        [scrollView setBorderType:NSNoBorder];
      }
    }
  }
  
  [self configureToolbar:window.toolbar];
}

- (void)adjustViewerWindow:(NSWindow *)window {
  [window setCollectionBehavior:window.collectionBehavior | NSWindowCollectionBehaviorFullScreenPrimary];
  
  for (NSView *subview in [[window contentView] subviews]) {
    if ([subview isKindOfClass:[NSTextField class]]) {
      NSTextField *textField = (NSTextField *)subview;
      [[textField cell] setBackgroundStyle:NSBackgroundStyleRaised];
    } else if ([subview isKindOfClass:[NSPopUpButton class]]) {
      NSPopUpButton *button = (NSPopUpButton *)subview;
      
      if (button.bezelStyle != NSTexturedRoundedBezelStyle) {
        [button setBezelStyle:NSTexturedRoundedBezelStyle];
        
        NSRect newFrame = button.frame;
        newFrame.size.height++;
        newFrame.origin.x -= 8;
        newFrame.origin.y--;
        button.frame = newFrame;
      }
    }
  }
  
  [self configureToolbar:window.toolbar];
}

#pragma mark Status Bar Visibility

- (void)addToggleStatusBarMenuItem {
  NSMenu *viewerMenu = [[[[NSApplication sharedApplication] mainMenu] itemWithTag:kViewerMenuTag] submenu];
  NSMenuItem *toggleStatusBar = [[NSMenuItem alloc] initWithTitle:self.statusMenuItemTitle action:@selector(toggleStatusBarShown:) keyEquivalent:@"/"];
  [(id)toggleStatusBar setTarget:self];
  [toggleStatusBar setKeyEquivalentModifierMask:NSCommandKeyMask];
  [viewerMenu addItem:toggleStatusBar];
}

- (void)toggleStatusBarShown:(NSMenuItem *)menuItem {
  self.statusBarHidden = !self.statusBarHidden;
  menuItem.title = self.statusMenuItemTitle;
  [self updateStatusBarShown];
}

- (NSString *)statusMenuItemTitle {
  return self.statusBarHidden ? @"Show Status Bar" : @"Hide Status Bar";
}

- (void)updateStatusBarShown {
  NSArray *windows = [[NSApplication sharedApplication] windows];
  
  for (NSWindow *window in windows) {
    if ([window.identifier isEqualToString:@"com.apple.QuartzComposer.editor.viewer"]) {
      NSWindow *viewerWindow = window;
      
      NSMutableArray *statusBarSubviews = [NSMutableArray array];
      NSView *renderView = nil;
      
      for (NSView *view in [[viewerWindow contentView] subviews]) {
        if ([view isKindOfClass:NSClassFromString(@"RenderView")]) {
          renderView = view;
        } else {
          [statusBarSubviews addObject:view];
        }
      }
      
      if (self.statusBarHeight < 1 && renderView) {
        self.statusBarHeight = [[viewerWindow contentView] bounds].size.height - [renderView frame].size.height;
      }
      
      NSRect windowFrame = [[viewerWindow contentView] bounds];
      
      if (self.statusBarHidden) {
        renderView.frame = windowFrame;
      } else {
        renderView.frame = NSMakeRect(0, self.statusBarHeight, windowFrame.size.width, windowFrame.size.height - self.statusBarHeight);
      }
      
      for (NSView *view in statusBarSubviews) {
        [view setHidden:self.statusBarHidden];
      }
    }
  }
}

- (BOOL)statusBarHidden {
  return [[NSUserDefaults standardUserDefaults] boolForKey:@"FBStatusBarHidden"];
}

- (void)setStatusBarHidden:(BOOL)flag {
  [[NSUserDefaults standardUserDefaults] setBool:flag forKey:@"FBStatusBarHidden"];
}

- (CGFloat)statusBarHeight {
  NSNumber *height = [[FBOrigamiAdditions sharedAdditions] associatedValueForKey:@"FBStatusBarHeight"];
  return height.floatValue;
}

- (void)setStatusBarHeight:(CGFloat)height {
  [[FBOrigamiAdditions sharedAdditions] associateValue:@(height) withKey:@"FBStatusBarHeight"];
}

#pragma mark Path Bar Visibility

- (void)addTogglePathBarMenuItem {
  NSMenu *editorMenu = [[[[NSApplication sharedApplication] mainMenu] itemWithTag:kEditorMenuTag] submenu];
  NSMenuItem *togglePathBar = [[NSMenuItem alloc] initWithTitle:self.pathBarMenuItemTitle action:@selector(togglePathBarShown:) keyEquivalent:@""];
  [(id)togglePathBar setTarget:self];
  [editorMenu addItem:[NSMenuItem separatorItem]];
  [editorMenu addItem:togglePathBar];
}

- (void)togglePathBarShown:(NSMenuItem *)menuItem {
  self.pathBarVisible = !self.pathBarVisible;
  menuItem.title = self.pathBarMenuItemTitle;
  [self updatePathBarShown];
}

- (void)updatePathBarShown {
  NSArray *windows = [[NSApplication sharedApplication] windows];
  
  for (NSWindow *window in windows) {
    if ([window.identifier isEqualToString:@"com.apple.QuartzComposer.editor.editor"]) {
      for (NSView *subview in [[window contentView] subviews]) {
        if ([subview isKindOfClass:NSClassFromString(@"QCEditorPatchPathView")]) {
          NSView *pathBar = subview;
          NSWindow *editorWindow = window;
          NSView *splitView = nil;
          
          for (NSView *view in [[editorWindow contentView] subviews]) {
            if ([view isKindOfClass:[NSSplitView class]]) {
              splitView = view;
            }
          }
          
          if (!self.pathBarVisible && !pathBar.isHidden) {
            pathBar.hidden = YES;
            
            NSRect newFrame = [splitView frame];
            newFrame.size.height += pathBar.frame.size.height;
            [splitView setFrame:newFrame];
          }
          else if (self.pathBarVisible && pathBar.isHidden) {
            pathBar.hidden = NO;
            
            NSRect newFrame = [splitView frame];
            newFrame.size.height -= pathBar.frame.size.height;
            [splitView setFrame:newFrame];
          }
        }
      }
    }
  }
}

- (NSString *)pathBarMenuItemTitle {
  return self.pathBarVisible ? @"Hide Path Bar" : @"Show Path Bar";
}

- (BOOL)pathBarVisible {
  return [[NSUserDefaults standardUserDefaults] boolForKey:@"FBPathBarVisible"];
}

- (void)setPathBarVisible:(BOOL)flag {
  [[NSUserDefaults standardUserDefaults] setBool:flag forKey:@"FBPathBarVisible"];
}

#pragma mark Toolbar Icons

- (void)configureToolbar:(NSToolbar *)toolbar {
  if ([toolbar associatedValueForKey:@"fb_toolbarConfigured"])
    return;

  NSArray *allToolbarItemDicts = [(NSObject *)toolbar.delegate valueForKey:@"_items"];
  NSMutableArray *allToolbarItems = [NSMutableArray array];

  for (NSDictionary *dict in allToolbarItemDicts) {
    id item = dict[@"item"];
    if ([item isKindOfClass:[NSToolbarItem class]])
      [allToolbarItems addObject:item];
  }
  
  for (NSToolbarItem *item in allToolbarItems) {
    NSImage *icon = self.toolbarIcons[item.itemIdentifier];
    if (icon) {
      item.image = icon;
    }
    else if ([item.itemIdentifier isEqualToString:@"zoom"]) {
      NSSegmentedControl *segmentedControl = (NSSegmentedControl *)item.view;
      for (int i = 0; i < 4; i++) {
        if (self.zoomIcons[i])
          [segmentedControl setImage:self.zoomIcons[i] forSegment:i];
      }
    }
    else if ([item.itemIdentifier isEqualToString:@"mode"]) {
      NSSegmentedControl *segmentedControl = (NSSegmentedControl *)item.view;
      for (int i = 0; i < 4; i++) {
        if (self.modeIcons[i])
          [segmentedControl setImage:self.modeIcons[i] forSegment:i];
      }
    }
  }
  
  for (NSToolbarItem *item in allToolbarItems) {
    if ([item.itemIdentifier isEqualToString:@"mode"]) {
      item.label = @"Device";
      item.paletteLabel = @"Device";

      NSSize size = NSMakeSize(116, 25);
      FBDeviceToolbarButton *button = [[FBDeviceToolbarButton alloc] initWithFrame:NSMakeRect(0, 14, size.width, size.height)];
      button.bezelStyle = NSTexturedRoundedBezelStyle;
      button.title = @"No Device";
      [(id)button setTarget:self];
      button.action = @selector(showDeviceMenu:);
      [button sizeToFit];
      item.view = button;
      item.minSize = size;
      item.maxSize = size;
    }
  }
  
  [toolbar associateValue:@YES withKey:@"fb_toolbarConfigured"];
}

- (void)showDeviceMenu:(FBDeviceToolbarButton *)button {
  NSPopover *popover = button.popover;
  
  if (!popover) {
    FBDeviceViewController *viewController = [[FBDeviceViewController alloc] initWithNibName:@"FBDeviceViewController" bundle:[FBOrigamiAdditions origamiBundle]];
    
    popover = [[NSPopover alloc] init];
    popover.contentViewController = viewController;
    popover.behavior = NSPopoverBehaviorSemitransient;
    button.popover = popover;
  }
  
  if (popover.shown) {
    [popover close];
  } else {
    [popover showRelativeToRect:NSZeroRect ofView:button preferredEdge:NSMaxYEdge];
  }
}

- (NSDictionary *)toolbarIcons {
  if (!toolbarIcons) {
    NSArray *itemIdentifiers = @[@"run", @"stop", @"parameters", @"saveImage", @"editor", @"present", // Viewer Window
                                 @"macro", @"parent", @"inspector", @"createVirtualMacro", @"inputParameters", @"viewer", @"showSettings", @"patcherator"]; // Editor Window
    
    NSMutableDictionary *icons = [NSMutableDictionary dictionary];
    
    for (NSString *identifier in itemIdentifiers) {
      NSImage *icon = [[NSImage alloc] initByReferencingFile:[[FBOrigamiAdditions origamiBundle] pathForImageResource:[identifier fb_capitalizeFirstLetter]]];
      
      if (icon)
        icons[identifier] = icon;
    }
    
    toolbarIcons = [NSDictionary dictionaryWithDictionary:icons];
  }
  
  return toolbarIcons;
}

- (NSArray *)zoomIcons {
  if (!zoomIcons) {
    NSArray *zoomIconNames = @[@"ZoomToFit", @"ZoomOut", @"ZoomToDefault", @"ZoomIn"];
    
    NSMutableArray *icons = [NSMutableArray array];
    
    for (NSString *name in zoomIconNames) {
      NSImage *icon = [[NSImage alloc] initByReferencingFile:[[FBOrigamiAdditions origamiBundle] pathForImageResource:name]];
      
      if (icon)
        [icons addObject:icon];
    }
    
    zoomIcons = [NSArray arrayWithArray:icons];
  }
  
  return zoomIcons;
}

- (NSArray *)modeIcons {
  if (!modeIcons) {
    NSArray *modeIconNames = @[@"PerformanceMode", @"EditMode", @"DebugMode", @"ProfileMode"];
    
    NSMutableArray *icons = [NSMutableArray array];
    
    for (NSString *name in modeIconNames) {
      NSImage *icon = [[NSImage alloc] initByReferencingFile:[[FBOrigamiAdditions origamiBundle] pathForImageResource:name]];
      
      if (icon)
        [icons addObject:icon];
    }
    
    modeIcons = [NSArray arrayWithArray:icons];
  }
  
  return modeIcons;
}

@end
