/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBViewerDimensionsPatch.h"
#import "QCView+FBAdditions.h"

@interface FBViewerDimensionsPatch ()
@property (weak, nonatomic) QCView *qcView;
@property (strong, nonatomic) NSMutableArray *observers;
@end

@implementation FBViewerDimensionsPatch : QCPatch

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8
{
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8
{
	return kQCPatchExecutionModeProvider;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8
{
	return kQCPatchTimeModeNone;
}

- (id)initWithIdentifier:(id)fp8
{
	if (self = [super initWithIdentifier:fp8]) {
    [[self userInfo] setObject:@"Viewer Info" forKey:@"name"];
  }

	return self;
}

- (void)updateSizeToFrame:(NSRect)frame {
  CGFloat scale = self.qcView.fb_backingScale;
  outputWidth.doubleValue = frame.size.width * scale;
  outputHeight.doubleValue = frame.size.height * scale;
}

- (void)enable:(QCOpenGLContext*)context {
  id value = self._renderingInfo.context.userInfo[@".QCView"];
  self.qcView = (QCView *)[value pointerValue];
  NSWindow *window = self.qcView.window;

  // Initial properties
  outputIsFullScreen.booleanValue = self.qcView.isFullScreen;
  outputHasFocus.booleanValue = ((window.isMainWindow && [NSApplication sharedApplication].isActive) || self.qcView.isFullScreen);
  [self performSelector:@selector(updateRetina) withObject:nil afterDelay:0]; // The retina machinery in Origami will execute after this method runs, so we have to push the retina test to the next run loop.
  
  if (self.qcView.isFullScreen) {
    NSWindow *fullScreenWindow = self.qcView._fullScreenWindow;
    [self updateSizeToFrame:fullScreenWindow.frame];
  } else {
    [self updateSizeToFrame:self.qcView.frame];
  }
  
  // Notifications
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  
  [self.observers addObject:[nc addObserverForName:NSWindowDidChangeBackingPropertiesNotification object:self.qcView.window queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
    BOOL isRetina = (self.qcView.fb_backingScale > 1.01);
    outputRetina.booleanValue = isRetina;
    [self updateSizeToFrame:self.qcView.frame];
  }]];
  
  [self.observers addObject:[nc addObserverForName:QCViewDidEnterFullScreenNotification object:self.qcView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
    outputIsFullScreen.booleanValue = YES;
    outputHasFocus.booleanValue = YES;
    
    NSWindow *fullScreenWindow = self.qcView._fullScreenWindow;
    [self updateSizeToFrame:fullScreenWindow.frame];
  }]];
  
  [self.observers addObject:[nc addObserverForName:QCViewDidExitFullScreenNotification object:self.qcView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
    outputIsFullScreen.booleanValue = NO;
    [self updateSizeToFrame:self.qcView.frame];
  }]];
  
  [self.observers addObject:[nc addObserverForName:NSWindowDidResizeNotification object:self.qcView.window queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
    [self updateSizeToFrame:self.qcView.frame];
  }]];
  
  [self.observers addObject:[nc addObserverForName:NSWindowDidBecomeMainNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
    NSWindow *mainWindow = notif.object;

    if (mainWindow == self.qcView._fullScreenWindow) {
      outputHasFocus.booleanValue = YES;
    } else {
      outputHasFocus.booleanValue = (mainWindow == window);
    }
  }]];
  
  [self.observers addObject:[nc addObserverForName:NSApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
    outputHasFocus.booleanValue = YES;
  }]];
  
  [self.observers addObject:[nc addObserverForName:NSApplicationDidResignActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
    outputHasFocus.booleanValue = NO;
  }]];
}

- (void)updateRetina {
  outputRetina.booleanValue = (self.qcView.fb_backingScale > 1.01);
}

- (void)disable:(QCOpenGLContext*)context {
  for (id observer in self.observers) {
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
  }
}

@end
