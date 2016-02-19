//
//  POPConverterPatch.h
//  FBOrigami
//
//  Created by Brandon Walkin on 7/1/14.
//
//

#import <SkankySDK/SkankySDK.h>

@interface POPConverterPatch : QCPatch {
  QCNumberPort *inputBounciness;
  QCNumberPort *inputSpeed;
  QCNumberPort *outputFriction;
  QCNumberPort *outputTension;
  QCNumberPort *outputMass;
}

@end
