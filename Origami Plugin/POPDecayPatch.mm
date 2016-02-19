//
//  POPDecayPatch.m
//  FBOrigami
//
//  Created by Kimon Tsinteris on 5/11/14.
//
//

#import "POPDecayPatch.h"
#import <POP/POP.h>
#import <POP/POPAnimatorPrivate.h>

@interface POPDecayPatch()
+ (POPAnimatableProperty *)animatableProperty;
@property (assign, nonatomic) CGFloat decayValue;
@end

@interface POPDecayPatchIteration : NSObject
{
@public
  POPAnimator *animator;
  POPDecayAnimation *decay;
  __weak POPDecayPatch *patch;
  double inputValue;
  double inputVelocity;
  double inputDeceleration;
  BOOL inputStartAnimatingSignal;
}
@end

@implementation POPDecayPatchIteration

- (instancetype)initWithPatch:(POPDecayPatch *)aPatch
{
  self = [super init];
  if (nil != self) {
    patch = aPatch;
    animator = [[POPAnimator alloc] init];
    animator.disableDisplayLink = YES;
    decay = [POPDecayAnimation animation];
    decay.property = [[patch class] animatableProperty];
    inputValue = DBL_MIN;
    inputVelocity = DBL_MIN;
    inputDeceleration = DBL_MIN;
  }
  return self;
}

- (void)stopAnimating
{
  [animator removeAllAnimationsForObject:patch];
}

- (void)startAnimating
{
  [animator addAnimation:decay forObject:patch key:@"anim"];
}

@end

@interface POPDecayPatch ()
{
  NSMutableArray *_iterations;
  NSUInteger _iterationIdx;
  double _previousTime;
}
@end

@implementation POPDecayPatch

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
    POPAnimatableProperty *prop = [POPAnimatableProperty propertyWithName:@"com.facebook.origami.POPDecay" initializer:^(POPMutableAnimatableProperty *prop) {
      prop.readBlock = ^(POPDecayPatch *patch, CGFloat values[]) {
        values[0] = patch.decayValue;
      };
      prop.writeBlock = ^(POPDecayPatch *patch, const CGFloat values[]) {
        patch.decayValue = values[0];
      };
      prop.threshold = 0.001;
    }];
    _property = prop;
  }
  return _property;
}

- (id)initWithIdentifier:(id)fp8 {
  if (self = [super initWithIdentifier:fp8]) {
    [inputDeceleration setMinDoubleValue:0];
    [inputDeceleration setMaxDoubleValue:1];
    [inputDeceleration setDoubleValue:0.998];
    _iterations = [NSMutableArray array];
  }
  return self;
}

- (CGFloat)decayValue
{
  assert(false);
  return outputValue.doubleValue;
}

- (void)setDecayValue:(CGFloat)value
{
  NSLog(@"output:%f", value);
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
  POPDecayPatchIteration *iteration;
  if (_iterationIdx < _iterations.count) {
    iteration = _iterations[_iterationIdx];
  } else {
    iteration = [[POPDecayPatchIteration alloc] initWithPatch:self];
    [_iterations addObject:iteration];
  }

  BOOL animating = inputStartAnimatingSignal.booleanValue;
  
  if (!animating) {
    outputValue.doubleValue = inputStartValue.doubleValue;
    iteration->inputStartAnimatingSignal = animating;
  } else {

    // stop existing animation
    if (animating != iteration->inputStartAnimatingSignal) {
      iteration->inputStartAnimatingSignal = animating;

      // stop animating
      [iteration stopAnimating];

      iteration->decay = [POPDecayAnimation animation];
      iteration->decay.property = [[self class] animatableProperty];
      //iteration->decay.removedOnCompletion = NO;

      iteration->decay.fromValue = @(0);
      iteration->decay.velocity = @(1000);
      iteration->decay.beginTime = time;
      iteration->decay.tracer.shouldLogAndResetOnCompletion = YES;
      [iteration->decay.tracer start];
//      iteration->inputVelocity = inputVelocity.doubleValue;
//      iteration->decay.velocity = @(iteration->inputVelocity);
//      
//      iteration->inputValue = inputStartValue.doubleValue;
//      iteration->decay.fromValue = @(iteration->inputValue);
//      
//      iteration->inputDeceleration = inputDeceleration.doubleValue;
//      iteration->decay.deceleration = iteration->inputDeceleration;
      
      [iteration startAnimating];
      NSLog(@"%@", iteration->decay);
    }
    
    // ensure not paused, thus writing output value even while quiesced
    //iteration->decay.paused = NO;

    NSLog(@"time:%f", time);
    // render using iteration animator
    [iteration->animator renderTime:time];
  }
  
  // note previous time
  _previousTime = time;
  return YES;
}

@end
