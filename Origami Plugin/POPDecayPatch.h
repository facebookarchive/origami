//
//  POPDecayPatch.h
//  FBOrigami
//
//  Created by Kimon Tsinteris on 5/11/14.
//
//

#import <SkankySDK/SkankySDK.h>

@interface POPDecayPatch : QCPatch {
  QCNumberPort *inputStartValue;
  QCNumberPort *inputDeceleration;
  QCNumberPort *inputVelocity;
  QCBooleanPort *inputStartAnimatingSignal;
  QCNumberPort *outputValue;
}

@end
