/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBCursorPatch.h"

@interface FBCursorPatch ()
@property (strong, nonatomic) NSTrackingArea *trackingAreaForWindow, *trackingAreaForFullScreen;
@property (strong, nonatomic) id didEnterFullScreenObserver;
@property (strong, nonatomic) id didExitFullScreenObserver;
@property (strong, nonatomic) id didResignMainObserver;
@property (strong, nonatomic) id didBecomeMainObserver;
@property (strong, nonatomic) id didResignActiveObserver;
@property BOOL mouseInside;
@end

@implementation FBCursorPatch

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8 {
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8 {
	return kQCPatchExecutionModeConsumer;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8 {
	return kQCPatchTimeModeNone;
}

- (id)initWithIdentifier:(id)fp8 {
	if (self = [super initWithIdentifier:fp8]) {
    [inputStyle setMaxIndexValue:5];
  }
  
	return self;
}

- (void)enable:(QCOpenGLContext *)context {
  id value = self._renderingInfo.context.userInfo[@".QCView"];
  QCView *qcView = [value pointerValue];
  NSWindow *window = qcView.window;
  
  self.trackingAreaForWindow = [[NSTrackingArea alloc] initWithRect:qcView.bounds options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways | NSTrackingInVisibleRect) owner:self userInfo:nil];
  [qcView addTrackingArea:self.trackingAreaForWindow];
  
  [self trackFullScreenViewer];
  
  _hasFocus = (window.isMainWindow && [NSApplication sharedApplication].isActive) || [qcView isFullScreen];
  
  // Notifications
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  
  self.didEnterFullScreenObserver = [nc addObserverForName:QCViewDidEnterFullScreenNotification object:qcView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
    [self trackFullScreenViewer];
    
    _hasFocus = YES;
  }];

  self.didExitFullScreenObserver = [nc addObserverForName:QCViewDidExitFullScreenNotification object:qcView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
    if (!CGCursorIsVisible()) {
      [NSCursor unhide];
    }
  }];
  
  self.didResignMainObserver = [nc addObserverForName:NSWindowDidResignMainNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
    NSWindow *theWindow = notif.object;
    BOOL viewerDidResignMain = (window == theWindow);
    
    if (viewerDidResignMain && !CGCursorIsVisible()) {
      [NSCursor unhide];
    }
  }];
  
  self.didBecomeMainObserver = [nc addObserverForName:NSWindowDidBecomeMainNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
    NSWindow *mainWindow = notif.object;
    if (mainWindow == qcView._fullScreenWindow) {
      _hasFocus = YES;
    } else {
      _hasFocus = (mainWindow == window);
    }
  }];
  
  self.didResignActiveObserver = [nc addObserverForName:NSApplicationDidResignActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
    _hasFocus = NO;
    if (!CGCursorIsVisible()) {
      [NSCursor unhide];
    }
  }];
}

- (void)trackFullScreenViewer {
  id value = self._renderingInfo.context.userInfo[@".QCView"];
  QCView *qcView = [value pointerValue];
  NSView *fullScreenView = [[qcView _fullScreenWindow] contentView];
  
  if (fullScreenView == nil) {
    return;
  }
  
  BOOL isAlreadyTracking = NO;
  for (NSTrackingArea *t in fullScreenView.trackingAreas) {
    if (t && self.trackingAreaForFullScreen == t) {
      isAlreadyTracking = YES;
    }
  }
  
  if (self.trackingAreaForFullScreen == nil || isAlreadyTracking == NO) {
    self.trackingAreaForFullScreen = [[NSTrackingArea alloc] initWithRect:fullScreenView.bounds options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways | NSTrackingInVisibleRect) owner:self userInfo:nil];
    [fullScreenView addTrackingArea:self.trackingAreaForWindow];
  }
}

- (void)disable:(QCOpenGLContext*)context {
  id value = self._renderingInfo.context.userInfo[@".QCView"];
  QCView *qcView = [value pointerValue];
  NSView *fullScreenView = [[qcView _fullScreenWindow] contentView];
  
  [qcView removeTrackingArea:self.trackingAreaForWindow];
  [fullScreenView removeTrackingArea:self.trackingAreaForFullScreen];
  
  if (!CGCursorIsVisible()) {
    [NSCursor unhide];
  }
  
  [[NSCursor arrowCursor] set];
  
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver:self.didEnterFullScreenObserver];
  [nc removeObserver:self.didExitFullScreenObserver];
  [nc removeObserver:self.didResignMainObserver];
  [nc removeObserver:self.didBecomeMainObserver];
  [nc removeObserver:self.didResignActiveObserver];
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
  if (inputStyle.wasUpdated && self.mouseInside)
    [self updateCursorStyle];
  
  return YES;
}

- (void)updateCursorStyle { // Only call when the mouse is inside the viewer window
  if ([inputStyle indexValue] == FBCursorStyleCrossHair) {
    [[NSCursor crosshairCursor] set];
  } else if ([inputStyle indexValue] == FBCursorStyleOpenHand) {
    [[NSCursor openHandCursor] set];
  } else if ([inputStyle indexValue] == FBCursorStyleClosedHand) {
    [[NSCursor closedHandCursor] set];
  } else if ([inputStyle indexValue] == FBCursorStyleIBeam) {
    [[NSCursor IBeamCursor] set];
  } else if ([inputStyle indexValue] == FBCursorStylePointingHand) {
    [[NSCursor pointingHandCursor] set];
  } else {
    [[NSCursor arrowCursor] set];
  }
}

#pragma mark NSTrackingArea calls

- (void)mouseEntered:(NSEvent *)anEvent {
  self.mouseInside = YES;
  
  if (CGCursorIsVisible() && _hasFocus && [inputHide booleanValue]) {
    [NSCursor hide];
  }
}

- (void)mouseExited:(NSEvent *)anEvent {
  self.mouseInside = NO;
  
  if (!CGCursorIsVisible() && _hasFocus) {
    [NSCursor unhide];
  }
  
  [[NSCursor arrowCursor] set];
}

- (void)mouseMoved:(NSEvent *)anEvent {
  if (_hasFocus) {
    if (CGCursorIsVisible() && [inputHide booleanValue]) {
      [NSCursor hide];
    }
    else if (!CGCursorIsVisible() && ![inputHide booleanValue]) {
      [NSCursor unhide];
    }
  }
  
  [self updateCursorStyle];
}

@end
