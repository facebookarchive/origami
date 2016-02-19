/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiAdditions+Retina.h"
#import "NSObject+FBAdditions.h"
#import "NSObject+AssociatedObjects.h"
#import "FBOrigamiAdditions+Preferences.h"

@interface FBOrigamiAdditions ()
- (void)original_startRendering:(BOOL)flag;
- (void)original_stopRendering;
@end

@implementation FBOrigamiAdditions (Retina)

- (void)setupRetina {
  [self fb_swizzleInstanceMethod:@selector(startRendering:) forClassName:@"RenderView"];
  [self fb_swizzleInstanceMethod:@selector(stopRendering) forClassName:@"RenderView"];
}

#pragma mark Retina Viewer

- (void)startRendering:(BOOL)flag {
  [self original_startRendering:flag];
  
  if (!FBOrigamiAdditions.isRetinaSupportEnabled) {
    return;
  }
  
  QCView *qcView = (QCView *)self;
  QCRenderView *renderView = qcView.subviews.lastObject;
  [renderView setWantsBestResolutionOpenGLSurface:YES];
  [qcView.openGLContext performSelector:@selector(update)];
  
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  
  [nc addObserverForName:NSWindowDidResizeNotification object:qcView.window queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
    NSWindow *window = note.object;
    if ([window backingScaleFactor] > 1.01) {
      [qcView.openGLContext performSelector:@selector(update)];
    }
  }];
  
  [nc addObserverForName:NSWindowDidChangeBackingPropertiesNotification object:qcView.window queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
    NSWindow *window = note.object;
    if ([window backingScaleFactor] > 1.01) {
      [qcView.openGLContext performSelector:@selector(update) withObject:nil afterDelay:0];
    }
  }];
  
  [nc addObserverForName:QCViewDidEnterFullScreenNotification object:qcView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
    [qcView.openGLContext performSelector:@selector(update) withObject:nil afterDelay:0];
  }];
  
  [nc addObserverForName:QCViewDidExitFullScreenNotification object:qcView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
    [qcView.openGLContext performSelector:@selector(update) withObject:nil afterDelay:0];
  }];
}

- (void)stopRendering {
  [self original_stopRendering];
  
  QCView *qcView = (QCView *)self;
  QCRenderView *renderView = qcView.subviews.lastObject;
  
  if (!(FBOrigamiAdditions.isRetinaSupportEnabled || renderView.wantsBestResolutionOpenGLSurface)) {
    return;
  }
  
  [renderView setWantsBestResolutionOpenGLSurface:NO];
}

@end
