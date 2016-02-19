/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <SkankySDK/SkankySDK.h>

@interface FBDragAndDropPatch : QCPatch {
  QCIndexPort *inputCursor;
	QCNumberPort *outputX;
	QCNumberPort *outputY;
  QCVirtualPort *outputPath;
  QCBooleanPort *outputDragging;
  QCBooleanPort *outputDropSignal;
}

@end
