/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOInteractionPatch.h"
#import "FBOInteractionController.h"
#import "NSObject+FBNoArcAdditons.h"
#import "BWDeviceInfoReceiver.h"

#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)

static CGFloat kTapTolerance = 10; // Slip distance in pixels

@interface FBOInteractionPatch ()
@property (weak, nonatomic) FBOInteractionController *controller;
@property (strong, nonatomic) NSEvent *currentEvent;
@property (strong, nonatomic) NSMutableDictionary *outputDowns;
@property (strong, nonatomic) NSMutableDictionary *outputUps;
@property (strong, nonatomic) NSMutableDictionary *outputTaps;
@property (strong, nonatomic) NSMutableDictionary *outputDrags;
@property (strong, nonatomic) NSMutableDictionary *touchDowns;
@end

@implementation FBOInteractionPatch

- (FBOInteractionController *)controller {
  if (_controller == nil) {
    FBOInteractionController *c = [FBOInteractionController controllerForPatch:self];
    if (c)
      self.controller = c;
  }
  
  return _controller;
}

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8 {
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8 {
	return kQCPatchExecutionModeProvider;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8 {
	return kQCPatchTimeModeTimeBase;
}

- (id)initWithIdentifier:(id)fp8 {
	if (self = [super initWithIdentifier:fp8]) {
    inputEnableInteraction.booleanValue = YES;
  }
  
	return self;
}

- (BOOL)setup:(QCOpenGLContext *)context {
  self.outputDowns = [NSMutableDictionary dictionary];
  self.outputUps = [NSMutableDictionary dictionary];
  self.outputTaps = [NSMutableDictionary dictionary];
  self.outputDrags = [NSMutableDictionary dictionary];
  self.touchDowns = [NSMutableDictionary dictionary];
  
  // Get a reference to the iterator so we can know its count and current index in -execute
  QCPatch *possibleIterator = [self parentPatch];
  
  while (possibleIterator != nil) {
    if ([possibleIterator isKindOfClass:NSClassFromString(@"QCIterator")]) {
      _iterator = possibleIterator;
      possibleIterator = nil;
    } else {
      possibleIterator = [possibleIterator parentPatch];
    }
  }
  
  return [super setup:context];
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments
{
  if (outputInteraction.rawValue != self)
    outputInteraction.rawValue = self;
  
  if (!inputEnableInteraction.booleanValue) return YES;
  
  NSUInteger iterationIndex = _iterator ? *(unsigned long long *)[_iterator fb_instanceVariableForKey:@"_currentIndex"] : 0;
  NSUInteger iterationCount = _iterator ? ((QCIndexPort *)[_iterator portForKey:@"inputCount"]).indexValue : 0;
  NSNumber *iterationKey = @(iterationIndex);
  
  // Pulse behavior
  if (((NSNumber *)self.outputUps[iterationKey]).boolValue) {
    self.outputUps[iterationKey] = @NO;
  }
  
  if (((NSNumber *)self.outputTaps[iterationKey]).boolValue) {
    self.outputTaps[iterationKey] = @NO;
  }
  
  NSEvent *event = arguments[@"QCRuntimeEventKey"];
  
  if (event) {
    self.currentEvent = event;
  }
  
  BOOL mouseDidGoDown = (event.type == NSLeftMouseDown);
  BOOL mouseDidGoUp = (event.type == NSLeftMouseUp);
  
  NSDictionary *touches = [self touches];
  BOOL _touchDown = ((NSNumber *)self.touchDowns[iterationKey]).boolValue;
  BOOL touchDown = (touches.count > 0);
  BOOL touchDidGoDown = touchDown && !_touchDown;
  BOOL touchDidGoUp = !touchDown && _touchDown;
  self.touchDowns[iterationKey] = @(touchDown);
  
  FBInputType inputType = touchDown ? FBInputTypeTouch : FBInputTypeMouse;
  
  if (mouseDidGoDown || touchDidGoDown) {
    NSPoint point = [self pointForInputType:inputType event:self.currentEvent];
    self.controller.downPoints[iterationKey] = [NSValue valueWithPoint:point];
    
    if (_sprite)
      [self.controller hitTestGraphWithPoint:point forInputType:inputType iteration:iterationKey.unsignedIntegerValue];
  }
  
  if (mouseDidGoDown || touchDidGoDown) {
    NSArray *hitPatches = self.controller.hitPatches[iterationKey];
    if (!_sprite || hitPatches.lastObject == _sprite) {
      self.outputDowns[iterationKey] = @YES;
      self.outputDrags[iterationKey] = @YES;
    }
  }
  else if (mouseDidGoUp || touchDidGoUp) {
    BOOL hasLastTouchPoint = self.controller.lastTouchPoints[iterationKey] != nil;
    NSPoint lastTouchPoint = ((NSValue *)self.controller.lastTouchPoints[iterationKey]).pointValue;
    NSPoint upPoint = hasLastTouchPoint ? lastTouchPoint : [self pointForInputType:inputType event:self.currentEvent];
    NSPoint downPoint = ((NSValue *)self.controller.downPoints[iterationKey]).pointValue;
    NSRect toleranceRect = NSMakeRect(downPoint.x - kTapTolerance / 2, downPoint.y - kTapTolerance / 2, kTapTolerance, kTapTolerance);
    if (NSPointInRect(upPoint, toleranceRect)) {
      self.outputTaps[iterationKey] = mouseDidGoUp ? @(outputDown.booleanValue) : @YES;
    }
    self.outputUps[iterationKey] = @(outputDown.booleanValue);
    self.outputDowns[iterationKey] = @NO;
    self.outputDrags[iterationKey] = @NO;
  }
  else if (((NSNumber *)self.outputDrags[iterationKey]).boolValue && _sprite) {
    NSPoint point = [self pointForInputType:inputType event:self.currentEvent];
    BOOL hitTest = [self.controller hitTestPatch:_sprite withPoint:point forInputType:inputType iteration:iterationKey.unsignedIntegerValue];
    self.outputDowns[iterationKey] = @(hitTest);
  }

  if (inputType == FBInputTypeTouch)
    self.controller.lastTouchPoints[iterationKey] = [NSValue valueWithPoint:[self currentTouchPoint]];
  else
    [self.controller.lastTouchPoints removeObjectForKey:iterationKey];
  
  // This patch executes before the sprite it's connected to has updated its port values, so it's operating on the port values of the previous iteration's sprite. Because of this we need to set our output values to the next iteration's values.
  NSUInteger nextIterationIndex = ((iterationIndex + 1) >= iterationCount) ? 0.0 : (iterationIndex + 1);
  NSNumber *nextIterationKey = @(nextIterationIndex);
  outputDown.booleanValue = ((NSNumber *)self.outputDowns[nextIterationKey]).boolValue;
  outputUp.booleanValue = ((NSNumber *)self.outputUps[nextIterationKey]).boolValue;
  outputTap.booleanValue = ((NSNumber *)self.outputTaps[nextIterationKey]).boolValue;
  outputDrag.booleanValue = ((NSNumber *)self.outputDrags[nextIterationKey]).boolValue;
  
  return YES;
}

- (NSPoint)pointForInputType:(FBInputType)inputType event:(NSEvent *)event {
  // If it's a touch down, return the touch point from the device in pixels
  if (inputType == FBInputTypeTouch)
    return [self currentTouchPoint];
  
  // If it's a mouse down, convert the position to the correct coordinates
  NSPoint point = NSZeroPoint;
  
  id value = self._renderingInfo.context.userInfo[@".QCView"];
  QCView *qcView = [value pointerValue];
  NSSize viewerSize = NSZeroSize;
  NSPoint pointInQCView = NSZeroPoint;
  
  if (qcView.isFullScreen) {
    NSView *contentView = ((NSWindow *)qcView._fullScreenWindow).contentView;
    viewerSize = contentView.frame.size;
    pointInQCView = [contentView convertPoint:event.locationInWindow fromView:nil];
  } else {
    viewerSize = qcView.frame.size;
    pointInQCView = [qcView convertPoint:event.locationInWindow fromView:nil];
  }
  
  self.controller.viewerSize = viewerSize;
  point = NSMakePoint(pointInQCView.x - (viewerSize.width / 2), pointInQCView.y - (viewerSize.height / 2));

  point = [self scalePointForRetina:point inQCView:qcView];
  
  return point;
}

- (NSPoint)scalePointForRetina:(NSPoint)point inQCView:(QCView *)qcView {
  NSWindow *window = qcView.isFullScreen ? qcView._fullScreenWindow : qcView.window;
  NSView *contentView = qcView.isFullScreen ? window.contentView : qcView.subviews.lastObject;
  
  BOOL isRetina = contentView.wantsBestResolutionOpenGLSurface && window.backingScaleFactor > 1.001;
  CGFloat scale = isRetina ? window.backingScaleFactor : 1.0;

  CGAffineTransform transform = CGAffineTransformMakeScale(scale,scale);
  point = CGPointApplyAffineTransform(point, transform);
  return point;
}

- (BOOL)interactionEnabled {
  return inputEnableInteraction.booleanValue;
}

#pragma mark QCInteractionPatch Protocol

- (void)setRenderingPatch:(QCPatch *)patch iteration:(NSUInteger)iteration {
  if (patch != _cachedRenderingPatch) {
    if (patch) {
      QCPatch *possibleUberSprite = patch;
      
      while (possibleUberSprite != nil && ![self.controller patchIsUberSprite:possibleUberSprite]) {
        possibleUberSprite = [possibleUberSprite parentPatch];
      }

      _sprite = possibleUberSprite;
    } else {
      _sprite = nil;
    }
    
    _cachedRenderingPatch = patch;
  }
}

#pragma mark Device Touches

- (NSPoint)currentTouchPoint {
  NSDictionary *touches = [self touches];
  NSDictionary *touch = touches.allValues.lastObject;
  return NSMakePoint([touch[@"x"] floatValue], [touch[@"y"] floatValue]);
}

- (NSDictionary *)touches {
  NSDictionary *deviceInfo = [BWDeviceInfoReceiver sharedReceiver].deviceInfo;
  NSDictionary *touches = deviceInfo[@"touches"];

  if (touches && [touches count] > 0)
    return touches;

  return nil;
}

@end
