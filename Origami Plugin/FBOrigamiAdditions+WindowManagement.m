/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiAdditions+WindowManagement.h"
#import "NSObject+AssociatedObjects.h"

@implementation FBOrigamiAdditions (WindowManagement)

- (void)setupWindowManagementMenuItems {
  NSMenu *windowMenu = [[[[NSApplication sharedApplication] mainMenu] itemWithTag:5] submenu];
  
  NSMenuItem *thirdsLayout = [[NSMenuItem alloc] initWithTitle:@"Resize to Thirds" action:@selector(layoutWindowsToThirds:) keyEquivalent:@"0"];
  [(id)thirdsLayout setTarget:self];
  thirdsLayout.keyEquivalentModifierMask = NSAlternateKeyMask|NSCommandKeyMask|NSControlKeyMask;
  
  NSMenuItem *pipLayout = [[NSMenuItem alloc] initWithTitle:@"Picture in Picture" action:@selector(layoutWindowsToPictureInPicture:) keyEquivalent:@"9"];
  [(id)pipLayout setTarget:self];
  pipLayout.keyEquivalentModifierMask = NSAlternateKeyMask|NSCommandKeyMask|NSControlKeyMask;
  
  NSMenuItem *multiMonitorLayout = [[NSMenuItem alloc] initWithTitle:@"Multi-Monitor Layout" action:@selector(layoutWindowsToMultiMonitor:) keyEquivalent:@"8"];
  [(id)multiMonitorLayout setTarget:self];
  multiMonitorLayout.keyEquivalentModifierMask = NSAlternateKeyMask|NSCommandKeyMask|NSControlKeyMask;
  
  [windowMenu addItem:[NSMenuItem separatorItem]];
  [windowMenu addItem:thirdsLayout];
  [windowMenu addItem:pipLayout];
  [windowMenu addItem:multiMonitorLayout];
}

#pragma mark Menu Actions

- (void)layoutWindowsToThirds:(NSMenuItem *)menuItem {
  NSWindowController *editorController = [self editorController];
  NSWindowController *viewerController = [self viewerController];
  
  [editorController.window removeChildWindow:viewerController.window];
  
  CGRect screenFrame = editorController.window.screen.visibleFrame;
  
  NSRect editorFrame = screenFrame;
  editorFrame.size.width = roundf((screenFrame.size.width / 3) * 2);
  [editorController.window setFrame:editorFrame display:YES animate:YES];
  
  NSRect viewerFrame = screenFrame;
  viewerFrame.origin.x = screenFrame.origin.x + roundf((screenFrame.size.width / 3) * 2);
  viewerFrame.size.width = roundf(screenFrame.size.width / 3);
  [viewerController.window setFrame:viewerFrame display:YES animate:YES];
  
  id observer = [viewerController associatedValueForKey:@"fb_fullScreenObserver"];
  if (observer)
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
}

- (void)layoutWindowsToPictureInPicture:(NSMenuItem *)menuItem {
  NSWindowController *editorController = [self editorController];
  NSWindowController *viewerController = [self viewerController];
  
  CGRect screenFrame = editorController.window.screen.visibleFrame;
  
  [viewerController.window.toolbar setVisible:NO];
  
  NSRect viewerFrame = screenFrame;
  CGFloat viewerSize = roundf(screenFrame.size.height / 4);
  viewerFrame.origin.x = screenFrame.origin.x + (screenFrame.size.width - viewerSize);
  viewerFrame.size.width = viewerSize;
  viewerFrame.size.height = viewerSize;
  [viewerController.window setFrame:viewerFrame display:YES animate:YES];
  
  id observer = [[NSNotificationCenter defaultCenter] addObserverForName:QCViewDidExitFullScreenNotification
                                                                  object:[viewerController performSelector:@selector(renderingView)]
                                                                   queue:[NSOperationQueue mainQueue]
                                                              usingBlock:^(NSNotification *note) {
                                                                NSView *renderView = note.object;
                                                                [editorController.window addChildWindow:renderView.window ordered:NSWindowAbove];
                                                              }];
  [viewerController associateValue:observer withKey:@"fb_fullScreenObserver"];
  
  [editorController.window setFrame:screenFrame display:YES animate:YES];
  [editorController.window addChildWindow:viewerController.window ordered:NSWindowAbove];
}

- (void)layoutWindowsToMultiMonitor:(NSMenuItem *)menuItem {
  if ([NSScreen screens].count > 1) {
    NSWindowController *editorController = [self editorController];
    NSWindowController *viewerController = [self viewerController];
    
    [editorController.window removeChildWindow:viewerController.window];
    [viewerController.window.toolbar setVisible:NO];
    
    CGRect mainScreenFrame = [(NSScreen *)[[NSScreen screens] objectAtIndex:0] visibleFrame];
    CGRect secondaryScreenFrame = [(NSScreen *)[[NSScreen screens] objectAtIndex:1] visibleFrame];
    
    [editorController.window setFrame:mainScreenFrame display:YES animate:YES];
    [viewerController.window setFrame:secondaryScreenFrame display:YES animate:YES];
    
    id observer = [viewerController associatedValueForKey:@"fb_fullScreenObserver"];
    if (observer)
      [[NSNotificationCenter defaultCenter] removeObserver:observer];
  }
}


@end
