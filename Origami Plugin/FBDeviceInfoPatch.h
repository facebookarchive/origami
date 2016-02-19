/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <Cocoa/Cocoa.h>

@interface FBDeviceInfoPatch : QCPatch
{
  QCBooleanPort *outputConnected;
  QCNumberPort *outputWidth;
  QCNumberPort *outputHeight;
  QCBooleanPort *outputIsPad;
  QCBooleanPort *outputIsPortrait;
  QCBooleanPort *outputIsRetina;
	QCStructurePort *outputTouches;
	QCStructurePort *output3DOrientation;
  QCStructurePort *outputAcceleration;
  QCStructurePort *outputRotationRate;
}

- (id)initWithIdentifier:(id)fp8;
- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments;

@end
