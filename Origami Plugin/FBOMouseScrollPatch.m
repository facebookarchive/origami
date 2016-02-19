/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOMouseScrollPatch.h"

#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)

@interface FBOMouseScrollPatch ()
@property BOOL momentumCompletePulse;
@property BOOL potentialStop;
@end

@implementation FBOMouseScrollPatch

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8 {
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8 {
	return kQCPatchExecutionModeProvider;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8 {
	return kQCPatchTimeModeNone;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
  NSEvent *event = arguments[@"QCRuntimeEventKey"];

  // Zero out the velocity if we detect the user is intentionally stopping the scroll.
  if (event == nil && self.potentialStop == YES) {
    outputXVelocity.doubleValue = 0;
    outputYVelocity.doubleValue = 0;
  }
  
  // Reset the momentum ended pulse after a frame.
  if (self.momentumCompletePulse) {
    outputDown.booleanValue = NO;
    self.momentumCompletePulse = NO;
  }
  
  if (event.type == NSScrollWheel) {
    CGFloat deltaX = event.scrollingDeltaX;
    CGFloat deltaY = event.scrollingDeltaY;
    outputXVelocity.doubleValue = deltaX;
    outputYVelocity.doubleValue = deltaY * -1;
    outputDown.booleanValue = (event.phase == NSEventPhaseBegan || event.phase == NSEventPhaseChanged || event.phase == NSEventPhaseMayBegin);
    
    // Synthesise the momentum ended event into our Down signal to support interrupting a scroll deceleration.
    if (event.momentumPhase == NSEventPhaseEnded) {
      self.momentumCompletePulse = YES;
      outputDown.booleanValue = YES;
    }
    
    // Heuristic to detect a potential stop. This happens when you swipe the mouse and stop without releasing your hand. The event handling system doesn't give us an event for this, so we need to detect it based on the last event.
    BOOL deltaIsLow = fequal(deltaY, -1.0) || fequal(deltaY, 1.0) || fequal(deltaX, -1.0) || fequal(deltaX, 1.0) ||
                      fequal(deltaY, -2.0) || fequal(deltaY, 2.0) || fequal(deltaX, -2.0) || fequal(deltaX, 2.0);
    self.potentialStop = NO;

    if (event.momentumPhase == NSEventPhaseNone && event.phase == NSEventPhaseChanged && deltaIsLow) {
      self.potentialStop = YES;
    }
  }

  return YES;
}

@end
