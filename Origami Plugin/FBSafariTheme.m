/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBSafariTheme.h"
#import "FBOrigamiAdditions.h"
#import "FBOrigamiAdditions+WindowMods.h"

@interface NSButton (SilenceXcode)
@property (weak) id target;
@end

@interface FBSafariTheme ()
@property BOOL statusBarWasVisible;
@end

@implementation FBSafariTheme

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8
{
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8
{
	return kQCPatchExecutionModeConsumer;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8
{
	return kQCPatchTimeModeIdle;
}

- (id)initWithIdentifier:(id)fp8
{
	if (self = [super initWithIdentifier:fp8]) {
    [inputWindowTitle setStringValue:@"Facebook"];
    [inputURL setStringValue:@"facebook.com"];
    [inputBackEnabled setBooleanValue:YES];
    [inputForwardEnabled setBooleanValue:NO];
  }
	return self;
}

- (void)enable:(QCOpenGLContext*)context {
  id value = self._renderingInfo.context.userInfo[@".QCView"];
  QCView *qcView = [value pointerValue];
  self.toolbarController = [FBSafariToolbarController controllerForQCView:qcView];
  
  self.cachedToolbar = [self.viewerWindow toolbar];
  self.cachedWindowTitle = self.viewerWindow.title;
  self.cachedCollectionBehavior = self.viewerWindow.collectionBehavior;
  self.cachedToolbarDisplayMode = self.cachedToolbar.displayMode;
  
  [self performSelector:@selector(browserifyViewerChrome) withObject:nil afterDelay:0];
}

- (void)browserifyViewerChrome {
  NSToolbar *safariToolbar = self.toolbarController.view.window.toolbar;
  [self.viewerWindow setToolbar:safariToolbar];
  
  if ([self.viewerWindow respondsToSelector:@selector(setTitleVisibility:)]) {
    self.viewerWindow.titleVisibility = NSWindowTitleHidden;
  }
  
  self.statusBarWasVisible = ![FBOrigamiAdditions sharedAdditions].statusBarHidden;
  
  if (self.statusBarWasVisible) {
    [[FBOrigamiAdditions sharedAdditions] performSelector:@selector(toggleStatusBarShown:) withObject:nil afterDelay:0];
  }
  
  [self.viewerWindow setCollectionBehavior:self.viewerWindow.collectionBehavior | NSWindowCollectionBehaviorFullScreenPrimary];
  
  for (NSToolbarItem *item in self.cachedToolbar.items) {
    if ([item.itemIdentifier isEqualToString:@"stop"]) {
      self.toolbarController.downloadsButton.target = item.target;
      self.toolbarController.downloadsButton.action = item.action;
    }
  }
  
  self.viewerWindow.title = [inputWindowTitle stringValue];
  [self.viewerWindow standardWindowButton:NSWindowDocumentIconButton].hidden = YES;

  [self.toolbarController.backForwardButtons setEnabled:[inputBackEnabled booleanValue] forSegment:0];
  [self.toolbarController.backForwardButtons setEnabled:[inputForwardEnabled booleanValue] forSegment:1];
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments
{
  if (![self.viewerWindow.title isEqualToString:[inputWindowTitle stringValue]]) {
    [self.viewerWindow performSelector:@selector(setTitle:) withObject:[inputWindowTitle stringValue] afterDelay:0];
  }
  
  if ([inputBackEnabled wasUpdated]) {
    [self.toolbarController.backForwardButtons setEnabled:[inputBackEnabled booleanValue] forSegment:0];
  }
  
  if ([inputForwardEnabled wasUpdated]) {
    [self.toolbarController.backForwardButtons setEnabled:[inputForwardEnabled booleanValue] forSegment:1];
  }
  
  if ([inputURL wasUpdated] || [inputFavicon wasUpdated]) {
    if ([inputURL wasUpdated]) {
      [self.toolbarController setURLLabel:[inputURL stringValue]];
    }

    if ([inputFavicon imageValue] == nil) {
      BOOL isFacebookURL = [[inputURL stringValue] rangeOfString:@"facebook.com"].location != NSNotFound;
      NSString *filename = isFacebookURL ? @"FaviconFacebook" : @"FaviconGeneric";
      
      NSBundle *bundle = [NSBundle bundleForClass:[self class]];
      NSImage *image = [[NSImage alloc] initByReferencingFile:[bundle pathForImageResource:filename]];
      [self.toolbarController setFaviconGraphic:image];
      
      if (!isFacebookURL && [inputURL stringValue]) {
          [NSThread detachNewThreadSelector:@selector(_fetchActualFavicon) toTarget:self withObject:nil];
      }
      
    } else {
      if ([inputFavicon wasUpdated]) {
        QCImage *qcImage = [inputFavicon imageValue];
        CGColorSpaceRef genericRGB = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
        id exporter = [NSClassFromString(@"QCExporter_CoreGraphics") exporterForImageManager:[QCImageManager sharedSoftwareImageManager]];
        CGImageRef imageRef = (__bridge CGImageRef)[exporter createRepresentationOfType:@"CGImage" withProvider:[qcImage provider] transformation:[qcImage transformation] bounds:[qcImage bounds] colorSpace:genericRGB options:0];
        NSImage *image = [[NSImage alloc] initWithCGImage:imageRef size:NSMakeSize([qcImage bounds].size.width, [qcImage bounds].size.height)];
        if (image)
          [self.toolbarController setFaviconGraphic:image];
      }
    }
  }
  
	return YES;
}

- (void)disable:(QCOpenGLContext*)context {
  if ([self respondsToSelector:@selector(restoreViewerChrome)]) {
    [self performSelector:@selector(restoreViewerChrome) withObject:nil afterDelay:0];
  }
}

- (void)restoreViewerChrome {
  if (self.viewerWindow) {
    if (self.cachedWindowTitle) {
      self.viewerWindow.title = self.cachedWindowTitle;
    }
    
    if (self.cachedToolbar) {
      [self.viewerWindow setToolbar:self.cachedToolbar];
      [self performSelector:@selector(restoreToolbarDisplayMode) withObject:nil afterDelay:0];
    }
    
    if ([self.viewerWindow respondsToSelector:@selector(setTitleVisibility:)]) {
      self.viewerWindow.titleVisibility = NSWindowTitleVisible;
    }
    
    [self.viewerWindow setCollectionBehavior:self.cachedCollectionBehavior];
    [self.viewerWindow standardWindowButton:NSWindowDocumentIconButton].hidden = NO;
    
    // If the status bar was visible before we browserfied the viewer and we hid it, then make it visible again when we de-browserify
    if (self.statusBarWasVisible && [FBOrigamiAdditions sharedAdditions].statusBarHidden) {
      [[FBOrigamiAdditions sharedAdditions] performSelector:@selector(toggleStatusBarShown:) withObject:nil afterDelay:0];
    }
  }
}

- (void)restoreToolbarDisplayMode {
  self.viewerWindow.toolbar.displayMode = self.cachedToolbarDisplayMode;
}

- (NSWindow *)viewerWindow {
  if (self.cachedViewerWindow == nil) {
    id value = self._renderingInfo.context.userInfo[@".QCView"];
    QCView *qcView = [value pointerValue];
    NSWindow *viewerWindow = [qcView window];
    
    if ([viewerWindow isKindOfClass:[NSWindow class]]) {
      self.cachedViewerWindow = viewerWindow;
    }
  }

  return self.cachedViewerWindow;
}

- (void)_fetchActualFavicon {
    NSString *formattedURL = [inputURL stringValue];
    if (![formattedURL hasPrefix:@"http"]) {
        formattedURL = [@"http://" stringByAppendingString:formattedURL];
    }
    
    NSURL *faviconURL = [NSURL URLWithString:[formattedURL stringByAppendingPathComponent:@"favicon.ico"]];
    NSImage *faviconImage = [[NSImage alloc] initWithContentsOfURL:faviconURL];
    
    if (!faviconImage) {
        NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL URLWithString:formattedURL] options:NSXMLDocumentTidyHTML error:nil];
        
        NSArray *nodes = [xmlDocument nodesForXPath:@"//link[lower-case(@rel)='shortcut icon']" error:nil];
        if ([nodes count]) {
            NSString *faviconURLCandidate = nil;
            NSArray *nodeAttributes = [[nodes lastObject] attributes];
            for (NSXMLNode *attribute in nodeAttributes) {
                if ([[attribute name] isEqualToString:@"href"]) {
                    faviconURLCandidate = [attribute objectValue];
                    break;
                }
            }
            if (![faviconURLCandidate hasPrefix:@"http"]) {
                faviconURLCandidate = [formattedURL stringByAppendingPathComponent:faviconURLCandidate];
            }
            
            faviconURL = [NSURL URLWithString:faviconURLCandidate];
            faviconImage = [[NSImage alloc] initWithContentsOfURL:faviconURL];
        }
    }
    
    if (faviconImage) {
        [self.toolbarController setFaviconGraphic:faviconImage];
    }
}


@end
