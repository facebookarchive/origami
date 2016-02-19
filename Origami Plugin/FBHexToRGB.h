/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <SkankySDK/SkankySDK.h>

@interface FBHexToRGB : QCPatch {
  QCStringPort *inputHex;
  QCNumberPort *outputRed;
  QCNumberPort *outputGreen;
  QCNumberPort *outputBlue;
}

@end
