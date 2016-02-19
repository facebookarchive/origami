/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBODelayPatch.h"

#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)
#define fequalzero(a) (fabs(a) < FLT_EPSILON)

static CGFloat kLowPassSmoothing = 0.97;

@interface FBODelayPatch ()
@property (strong, nonatomic) NSMutableDictionary *valueLists; // Key: Iteration index, Value: NSMutableArray queue
@property NSUInteger iterationCount;
@property double previousTime;
@property CGFloat lastFPS;
@property CGFloat savedFPS;
@end

@implementation FBODelayPatch

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8 {
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8 {
	return kQCPatchExecutionModeProcessor;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8 {
	return kQCPatchTimeModeTimeBase;
}

- (id)initWithIdentifier:(id)fp8 {
	if (self = [super initWithIdentifier:fp8]) {
    inputDuration.minDoubleValue = 0;
    inputDuration.doubleValue = 0.5;
    inputStyle.maxIndexValue = 2;
  }
  
	return self;
}

- (void)enable:(QCOpenGLContext*)context {
  self.valueLists = [NSMutableDictionary dictionary];
  self.savedFPS = -1;
  [super enable:context];
}

- (void)disable:(QCOpenGLContext*)context {
  self.valueLists = nil;
  [super disable:context];
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
  BOOL frameDidStart = (time != self.previousTime);
  self.previousTime = time;
  self.iterationCount = frameDidStart ? 0 : self.iterationCount + 1;
  
  NSValue *value = self._renderingInfo.context.userInfo[@".QCView"];
  QCView *qcView = [value pointerValue];
  
  // Put the FPS through a low-pass filter to stabilize it
  if (frameDidStart)
    self.lastFPS = (self.lastFPS * kLowPassSmoothing) + ((1 - kLowPassSmoothing) * qcView.averageFPS);
  
  CGFloat fps = self.lastFPS;
  NSUInteger durationInFrames = lround(inputDuration.doubleValue * fps);
  
  if (durationInFrames == 0) {
    [self setOutputRawValue:inputValue.value];
    return YES;
  }
  
  NSNumber *iterationKey = @(self.iterationCount);
  NSMutableArray *values = self.valueLists[iterationKey];
  
  if (!values) {
    values = [NSMutableArray array];
    self.valueLists[iterationKey] = values;
  }
  
  BOOL shouldDelay = ![self shouldSuppressDelay];

  if (shouldDelay) {
    NSInteger index = values.count - durationInFrames; // Assuming duration is in frames
    if (values.count > 0 && index < values.count && values[index]) {
      // Output the value n frames ago
      [self setOutputRawValue:values[index]];
      
      // Remove the value and all values before it
      NSInteger buffer = 10; // We need to give our queue some buffer at the start, in case the FPS fluctuates
      if ((index - buffer) > 0)
        [values removeObjectsInRange:NSMakeRange(0, (index - buffer))];
    }
    else {
      outputValue.value = nil;
    }
  } else {
    [values removeAllObjects];
    [self setOutputRawValue:inputValue.value];
  }
  
  // Add the current value to the top of the queue
  if (inputValue.value)
    [values addObject:inputValue.value];
  else
    [values addObject:[NSNull null]];
  
  return YES;
}

- (void)setOutputRawValue:(id)value {
  // Avoid setting the output value to NSNull since this breaks execution for some reason
  if (value == [NSNull null])
    value = nil;
  
  outputValue.rawValue = value;
}

- (BOOL)shouldSuppressDelay {
  // Don't supress if style is Delay Always
  if (inputStyle.indexValue == 0)
    return NO;
  
  // Only support delay style for Number and Boolean types
  if (![inputValue.value isKindOfClass:[NSNumber class]])
    return NO;
  
  // Don't delay if the duration is zero
  if (fequalzero(inputDuration.doubleValue))
    return YES;
  
  NSNumber *iterationKey = @(self.iterationCount);
  NSMutableArray *values = self.valueLists[iterationKey];
  
  CGFloat currentValue = 0, previousValue = 0;
  
  if ([inputValue.value respondsToSelector:@selector(floatValue)])
    currentValue = ((NSNumber *)inputValue.value).floatValue;
  
  if ([values.lastObject respondsToSelector:@selector(floatValue)]) // Can be NSNull
    previousValue = ((NSNumber *)values.lastObject).floatValue;
  
  if (fequal(currentValue, previousValue))
    return NO;
  else if (currentValue > previousValue && inputStyle.indexValue == 1) // If value is increasing and style is set to only delay increasing
    return NO;
  else if (currentValue < previousValue && inputStyle.indexValue == 2) // If value is decreasing and style is set to only delay decreasing
    return NO;
    
  return YES;
}

@end
