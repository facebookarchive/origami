//
//  POPConverterPatch.m
//  FBOrigami
//
//  Created by Brandon Walkin on 7/1/14.
//
//

#import "POPConverterPatch.h"
#import <POP/POP.h>

@implementation POPConverterPatch

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8 {
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8 {
	return kQCPatchExecutionModeProcessor;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8 {
	return kQCPatchTimeModeNone;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
  if (inputBounciness.wasUpdated || inputSpeed.wasUpdated) {
    double springBounciness = inputBounciness.doubleValue;
    double springSpeed = inputSpeed.doubleValue;
    double dynamicsTension = 0;
    double dynamicsFriction = 0;
    double dynamicsMass = 0;

    [POPSpringAnimation convertBounciness:springBounciness speed:springSpeed toTension:&dynamicsTension friction:&dynamicsFriction mass:&dynamicsMass];
    
    outputTension.doubleValue = dynamicsTension;
    outputFriction.doubleValue = dynamicsFriction;
    outputMass.doubleValue = dynamicsMass;
  }
  
  return YES;
}

@end
