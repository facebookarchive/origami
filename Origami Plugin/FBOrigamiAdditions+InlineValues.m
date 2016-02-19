/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiAdditions+InlineValues.h"
#import "NSObject+AssociatedObjects.h"
#import "GRPHookMethod.h"
#import "QCPort+FBAdditions.h"
#import "NSObject+FBAdditions.h"
#import "FBPatchView.h"
#import "QCPatch+FBAdditions.h"
#import "FBOLiveFilePatch.h"

static CGFloat kImageLoaderMaxHeightDelta = 80.0;

@interface FBOrigamiAdditions ()
- (NSSize)original_sizeForNode:(GFNode *)node;
- (void)original__drawNode:(GFNode *)node bounds:(NSRect)bounds;
@end

@implementation FBOrigamiAdditions (InlineValues)

- (void)setupInlineValues {
  // Add menu item for turning this feature on and off
  self.inlineValuesDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"FBInlineValuesDisabled"];
  self.inlineValuesMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Inline Values" action:@selector(toggleInlineValuesEnabled:) keyEquivalent:@"v"];
  self.inlineValuesMenuItem.keyEquivalentModifierMask = NSAlternateKeyMask|NSCommandKeyMask|NSControlKeyMask;
  [(id)self.inlineValuesMenuItem setTarget:self];
  self.inlineValuesMenuItem.state = !self.inlineValuesDisabled;
  [self.origamiMenu addItem:self.inlineValuesMenuItem];

  if (FBToolsIsInstalled()) {
    [self.origamiMenu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *debug = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Debug (FB Only)" action:NULL keyEquivalent:@""];
    NSMenu *debugMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""];
    [self.origamiMenu addItem:debug];
    [self.origamiMenu setSubmenu:debugMenu forItem:debug];
    
    self.textBackgroundsDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"FBTextBackgroundsDisabled"];
    self.textBackgroundsMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Text Backgrounds" action:@selector(toggleTextBackgroundsEnabled:) keyEquivalent:@""];
    [(id)self.textBackgroundsMenuItem setTarget:self];
    self.textBackgroundsMenuItem.state = !self.textBackgroundsDisabled;
    [debugMenu addItem:self.textBackgroundsMenuItem];
    
    self.checkboxesDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"FBCheckboxesDisabled"];
    self.checkboxesMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Checkboxes" action:@selector(toggleCheckboxesEnabled:) keyEquivalent:@""];
    [(id)self.checkboxesMenuItem setTarget:self];
    self.checkboxesMenuItem.state = !self.checkboxesDisabled;
    [debugMenu addItem:self.checkboxesMenuItem];
    
    self.customColorDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"FBCustomColorDisabled"];
    self.customColorMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Custom Text Background Color" action:@selector(toggleCustomColorEnabled:) keyEquivalent:@""];
    [(id)self.customColorMenuItem setTarget:self];
    self.customColorMenuItem.state = !self.customColorDisabled;
    [debugMenu addItem:self.customColorMenuItem];
    
    self.coreTextDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"FBCoreTextDisabled"];
    self.coreTextMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Core Text" action:@selector(toggleCoreTextEnabled:) keyEquivalent:@""];
    [(id)self.coreTextMenuItem setTarget:self];
    self.coreTextMenuItem.state = !self.coreTextDisabled;
    [debugMenu addItem:self.coreTextMenuItem];
  }
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(graphDidChange:) name:@"GFGraphEditorViewGraphDidChangeNotification" object:nil];

  [self fb_swizzleInstanceMethod:@selector(sizeForNode:) forClassName:@"QCPatchActor"];
  [self fb_swizzleInstanceMethod:@selector(_drawNode:bounds:) forClassName:@"GFGraphView"];
  
  if (!self.inlineValuesDisabled) {
    [self updateValues];
  }
  
  GRPHookMethod(NSClassFromString(@"QCPatchView"), @selector(drawRect:), ^(QCPatchView *self, NSRect dirtyRect) {
    GRPCallOriginal(dirtyRect);
    
    FBPatchView *pv = [self associatedValueForKey:@"fb_FBPatchView"];
    
    [pv setFrame:self.frame];
    [pv.superview setFrame:self.superview.frame];
    [pv setBounds:self.bounds];
    [pv.superview setBounds:self.superview.bounds];
    
    [pv displayIfNeeded];
  });
  
  GRPHookMethod(NSClassFromString(@"GFGraphView"), @selector(_imageForSelection), ^(GFGraphView *self) {
    id image;
    if (![FBOrigamiAdditions sharedAdditions].inlineValuesDisabled) {
      [self associateValue:[NSNumber numberWithBool:YES] withKey:@"fb_isOptionDragging"];
      image = GRPCallOriginal();
      [self associateValue:nil withKey:@"fb_isOptionDragging"];
    } else {
      image = GRPCallOriginal();
    }
    return image;
  });
}

- (void)_drawNode:(GFNode *)node bounds:(NSRect)bounds {
  if (![FBOrigamiAdditions sharedAdditions].inlineValuesDisabled) {
    if (![self associatedValueForKey:@"fb_isOptionDragging"]) {
      CGContextRef c = [[NSGraphicsContext currentContext] graphicsPort];
      CGAffineTransform a = CGContextGetCTM(c);
      NSValue *value = [NSValue valueWithBytes:&a objCType:@encode(CGAffineTransform)];
      [self associateValue:value withKey:@"fb_transform"];
    }
  }
  
  [self original__drawNode:node bounds:bounds];
}

- (NSSize)sizeForNode:(GFNode *)node {
  NSSize size = [self original_sizeForNode:node];

  // Resize image patches to show thumbnails in-line
  if (![FBOrigamiAdditions sharedAdditions].inlineValuesDisabled) {
    static Class QCImageLoader;
    if (!QCImageLoader)
      QCImageLoader = NSClassFromString(@"QCImageLoader");
    
    BOOL patchIsImageLoader = [node isMemberOfClass:QCImageLoader];
    BOOL patchIsLiveImage = [node isMemberOfClass:[FBOLiveFilePatch class]];
    
    if (patchIsImageLoader || patchIsLiveImage) {
      NSImage *image = patchIsImageLoader ? [FBPatchView imageForImageLoader:(QCPatch *)node] : [(FBOLiveFilePatch *)node cachedNSImage];
      NSSize maximumActorSize = NSMakeSize(size.width, size.height + kImageLoaderMaxHeightDelta);
      NSRect imageRect = [FBPatchView imageRectForActorSize:maximumActorSize originalImageSize:image.size];
      
      // TODO: Test to see whether the image has valid reps. This doesn't check for non-empty URLs that aren't valid.
      BOOL noURL = patchIsLiveImage && ((QCStringPort *)node.inputPorts[0]).stringValue.length < 1;
      
      if (!noURL)
        size.height += imageRect.size.height + 7.0;
    }
  }
  
  // Resize patches with interaction ports in some cases to work around the bug where ports can get clipped
  if ([self isMemberOfClass:[QCInteractionPatchActor class]]) {
    NSUInteger inputInteractionCount = 0;
    NSUInteger outputInteractionCount = 0;
    CGFloat heightDelta = 12;
    
    for (QCPort *port in node.inputPorts) {
      if (port.baseClass == [QCInteractionPort class])
        inputInteractionCount++;
    }
    
    for (QCPort *port in node.outputPorts) {
      if (port.baseClass == [QCInteractionPort class])
        outputInteractionCount++;
    }
    
    if (inputInteractionCount == 1 && outputInteractionCount == 0) {
      if ((node.inputPorts.count - 1) < node.outputPorts.count) {
        size.height += heightDelta;
      }
    }
    else if (inputInteractionCount == 0 && outputInteractionCount == 1) {
      if ((node.outputPorts.count - 1) < node.inputPorts.count) {
        size.height += heightDelta;
      }
    }
  }

  return size;
}

- (void)updateValues {
  FBPatchView *pv = [self.patchView associatedValueForKey:@"fb_FBPatchView"];
  [pv setNeedsDisplay:YES];
  
  if (!self.inlineValuesDisabled)
    [self performSelector:@selector(updateValues) withObject:nil afterDelay:0.05];
}

- (void)graphDidChange:(NSNotification *)notif {
  QCPatchEditorView *editorView = notif.object;
  GFGraphView *graphView = editorView.graphView;
  
  if (![graphView associatedValueForKey:@"fb_FBPatchView"]) {
    // Create the child window
    NSView *editorWindowContentView = (NSView *)graphView.window.contentView;
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(graphView.window.frame.origin.x, graphView.window.frame.origin.y, editorWindowContentView.frame.size.width, editorWindowContentView.frame.size.height) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
    window.backgroundColor = [NSColor clearColor];
    [window setOpaque:NO];
    [graphView.window addChildWindow:window ordered:NSWindowAbove];
    [window makeKeyAndOrderFront:nil];
    
    // Resize the child window with the parent
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidResizeNotification
                                                      object:graphView.window
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                    NSWindow *graphViewWindow = note.object;
                                                    NSView *graphViewContentView = graphViewWindow.contentView;
                                                    [window setFrame:NSMakeRect(graphViewWindow.frame.origin.x, graphViewWindow.frame.origin.y, graphViewContentView.frame.size.width, graphViewContentView.frame.size.height) display:YES];
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidChangeBackingPropertiesNotification
                                                      object:graphView.window
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                    NSWindow *graphViewWindow = note.object;
                                                    NSView *graphViewContentView = graphViewWindow.contentView;
                                                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                                      [window setFrame:NSMakeRect(graphViewWindow.frame.origin.x, graphViewWindow.frame.origin.y, graphViewContentView.frame.size.width, graphViewContentView.frame.size.height) display:YES];
                                                    });
                                                  }];
    
    // Create the clip view and patch view
    NSClipView *clipView = [[NSClipView alloc] initWithFrame:graphView.superview.frame];
    clipView.bounds = graphView.superview.bounds;
    clipView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [clipView setDrawsBackground:NO];
    [window.contentView addSubview:clipView];
    
    FBPatchView *pv = [[FBPatchView alloc] initWithFrame:graphView.frame];
    pv.graphView = graphView;
    [clipView setDocumentView:pv];
    pv.bounds = graphView.bounds;
  
    [graphView weaklyAssociateValue:pv withKey:@"fb_FBPatchView"];
  }
}

- (void)toggleInlineValuesEnabled:(NSMenuItem *)menuItem {
  self.inlineValuesDisabled = !self.inlineValuesDisabled;
  
  [[NSUserDefaults standardUserDefaults] setBool:self.inlineValuesDisabled forKey:@"FBInlineValuesDisabled"];
  
  self.inlineValuesMenuItem.state = !self.inlineValuesDisabled;
  
  if (!self.inlineValuesDisabled)
    [self updateValues];
  
  [[FBOrigamiAdditions sharedAdditions].patchView setNeedsDisplay:YES];
}

- (void)toggleTextBackgroundsEnabled:(NSMenuItem *)menuItem {
  self.textBackgroundsDisabled = !self.textBackgroundsDisabled;
  
  [[NSUserDefaults standardUserDefaults] setBool:self.textBackgroundsDisabled forKey:@"FBTextBackgroundsDisabled"];
  
  self.textBackgroundsMenuItem.state = !self.textBackgroundsDisabled;
  
  [[FBOrigamiAdditions sharedAdditions].patchView setNeedsDisplay:YES];
}

- (void)toggleCheckboxesEnabled:(NSMenuItem *)menuItem {
  self.checkboxesDisabled = !self.checkboxesDisabled;
  
  [[NSUserDefaults standardUserDefaults] setBool:self.checkboxesDisabled forKey:@"FBCheckboxesDisabled"];
  
  self.checkboxesMenuItem.state = !self.checkboxesDisabled;
  
  [[FBOrigamiAdditions sharedAdditions].patchView setNeedsDisplay:YES];
}

- (void)toggleCustomColorEnabled:(NSMenuItem *)menuItem {
  self.customColorDisabled = !self.customColorDisabled;
  
  [[NSUserDefaults standardUserDefaults] setBool:self.customColorDisabled forKey:@"FBCustomColorDisabled"];
  
  self.customColorMenuItem.state = !self.customColorDisabled;
  
  [[FBOrigamiAdditions sharedAdditions].patchView setNeedsDisplay:YES];
}

- (void)toggleCoreTextEnabled:(NSMenuItem *)menuItem {
  self.coreTextDisabled = !self.coreTextDisabled;
  
  [[NSUserDefaults standardUserDefaults] setBool:self.coreTextDisabled forKey:@"FBCoreTextDisabled"];
  
  self.coreTextMenuItem.state = !self.coreTextDisabled;
  
  [[FBOrigamiAdditions sharedAdditions].patchView setNeedsDisplay:YES];
}

@end
