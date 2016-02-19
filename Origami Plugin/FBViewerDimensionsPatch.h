/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

@interface FBViewerDimensionsPatch : QCPatch
{
	QCNumberPort *outputWidth;
	QCNumberPort *outputHeight;
  QCBooleanPort *outputIsFullScreen;
  QCBooleanPort *outputHasFocus;
  QCBooleanPort *outputRetina;
}

@end