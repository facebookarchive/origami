/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBSafariSegmentedCell.h"

@implementation FBSafariSegmentedCell

- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView {
  self.downSegment = self.selectedSegment;
  
  if (self.selectedSegment == 0) {
    self.toolbarController.backDown = YES;
  } else {
    self.toolbarController.forwardDown = YES;
  }
  
  return [super startTrackingAt:startPoint inView:controlView];
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag {
  if (self.downSegment == 0) {
    self.toolbarController.backDown = NO;
  } else {
    self.toolbarController.forwardDown = NO;
  }
  
  return [super stopTracking:lastPoint at:stopPoint inView:controlView mouseIsUp:flag];
}

@end
