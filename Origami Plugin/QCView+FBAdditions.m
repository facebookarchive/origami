/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "QCView+FBAdditions.h"

@implementation QCView (FBAdditions)

- (CGFloat)fb_backingScale {
  QCView *qcView = self;
  NSWindow *window = qcView.isFullScreen ? qcView._fullScreenWindow : qcView.window;
  NSView *contentView = qcView.isFullScreen ? window.contentView : qcView.subviews.lastObject;
  
  BOOL isRetina = contentView.wantsBestResolutionOpenGLSurface && window.backingScaleFactor > 1.001;
  CGFloat scale = isRetina ? window.backingScaleFactor : 1.0;
  return scale;
}

@end
