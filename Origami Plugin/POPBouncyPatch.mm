//
//  POPBouncyPatch.m
//  FBOrigami
//
//  Created by Kimon Tsinteris on 5/11/14.
//
//

#import "POPBouncyPatch.h"
#import <POP/POP.h>
#import <POP/POPAnimatorPrivate.h>

@interface POPBouncyPatch()
+ (POPAnimatableProperty *)animatableProperty;
@property (assign, nonatomic) CGFloat bouncyValue;
@end

@interface POPBouncyPatchIteration : NSObject
{
@public
  POPAnimator *animator;
  POPSpringAnimation *spring;
  __weak POPBouncyPatch *patch;
  double inputValue;
  double inputTension;
  double inputFriction;
  double inputMass;
}
@end

@implementation POPBouncyPatchIteration

static NSString * const kPOPBouncyPatchKey = @"key";

- (instancetype)initWithPatch:(POPBouncyPatch *)aPatch
{
  self = [super init];
  if (nil != self) {
    patch = aPatch;
    animator = [[POPAnimator alloc] init];
    animator.disableDisplayLink = YES;
    spring = [POPSpringAnimation animation];
    spring.property = [[patch class] animatableProperty];
    spring.removedOnCompletion = NO;
    [animator addAnimation:spring forObject:aPatch key:kPOPBouncyPatchKey];
    inputValue = DBL_MIN;
    inputTension = DBL_MIN;
    inputFriction = DBL_MIN;
    inputMass = DBL_MIN;
  }
  return self;
}
@end

@interface POPBouncyPatch ()
{
  NSMutableArray *_iterations;
  NSUInteger _iterationIdx;
  double _previousTime;
}
@end

@implementation POPBouncyPatch

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

+ (POPAnimatableProperty *)animatableProperty
{
  static POPAnimatableProperty *_property = nil;
  if (!_property) {
    POPAnimatableProperty *prop = [POPAnimatableProperty propertyWithName:@"com.facebook.origami.POPBouncy" initializer:^(POPMutableAnimatableProperty *prop) {
      prop.readBlock = ^(POPBouncyPatch *patch, CGFloat values[]) {
        values[0] = patch.bouncyValue;
      };
      prop.writeBlock = ^(POPBouncyPatch *patch, const CGFloat values[]) {
        patch.bouncyValue = values[0];
      };
      prop.threshold = 0.001;
    }];
    _property = prop;
  }
  return _property;
}

- (id)initWithIdentifier:(id)fp8 {
  if (self = [super initWithIdentifier:fp8]) {
    [inputTension setMinDoubleValue:0];
    [inputTension setMaxDoubleValue:1000];
    [inputTension setDoubleValue:342];
    [inputFriction setMinDoubleValue:0];
    [inputFriction setMaxDoubleValue:1000];
    [inputFriction setDoubleValue:20];
    [inputMass setMinDoubleValue:0];
    [inputMass setMaxDoubleValue:1000];
    [inputMass setDoubleValue:1];
    _iterations = [NSMutableArray array];
  }
  return self;
}

- (CGFloat)bouncyValue
{
  return outputValue.doubleValue;
}

- (void)setBouncyValue:(CGFloat)value
{
  [outputValue setDoubleValue:value];
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments
{
  // started & stopped viewer, reset any existing iterations
  if (_previousTime > time) {
    [_iterations removeAllObjects];
  }
  
  // determine iterator index based on time frame
  _iterationIdx = (time != _previousTime) ? 0 : _iterationIdx + 1;

  // get the current iteration
  POPBouncyPatchIteration *iteration;
  if (_iterationIdx < _iterations.count) {
    iteration = _iterations[_iterationIdx];
  } else {
    iteration = [[POPBouncyPatchIteration alloc] initWithPatch:self];
    [_iterations addObject:iteration];
  }

  // update input toValue on per iteration change
  if (iteration->inputValue != inputValue.doubleValue) {
    iteration->inputValue = inputValue.doubleValue;
    iteration->spring.toValue = @(iteration->inputValue);
    
    // if we have velocity signal, input that as well
    if (inputVelocitySignal.booleanValue) {
      iteration->spring.velocity = @(inputVelocity.doubleValue);
    }
  }

  // lazy initialize from value to to value; avoid initial animation from zero
  if (!iteration->spring.fromValue) {
    iteration->spring.fromValue = iteration->spring.toValue;
  }
  
  // update input dynamics on per iteration change
  if (iteration->inputTension != inputTension.doubleValue) {
    iteration->inputTension = inputTension.doubleValue;
    iteration->spring.dynamicsTension = iteration->inputTension;
  }

  if (iteration->inputFriction != inputFriction.doubleValue) {
    iteration->inputFriction = inputFriction.doubleValue;
    iteration->spring.dynamicsFriction = iteration->inputFriction;
  }

  if (iteration->inputMass != inputMass.doubleValue) {
    iteration->inputMass = inputMass.doubleValue;
    iteration->spring.dynamicsMass = iteration->inputMass;
  }

  // ensure not paused, thus writing output value even while quiesced
  iteration->spring.paused = NO;
  
  // render using iteration animator
  [iteration->animator renderTime:time];

  // note previous time
  _previousTime = time;
  return YES;
}

@end
