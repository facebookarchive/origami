//
//  POPBouncyPatch.h
//  FBOrigami
//
//  Created by Kimon Tsinteris on 5/11/14.
//
//

#import <SkankySDK/SkankySDK.h>

@interface POPBouncyPatch : QCPatch {
  QCNumberPort *inputValue;
  QCNumberPort *inputFriction;
  QCNumberPort *inputTension;
  QCNumberPort *inputMass;
  QCNumberPort *inputVelocity;
  QCBooleanPort *inputVelocitySignal;
  QCNumberPort *outputValue;
}

@end
