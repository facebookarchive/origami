/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <SkankySDK/SkankySDK.h>

@interface FBOInteractionPatch : QCPatch <QCInteractionPatch> {
  QCBooleanPort *inputEnableInteraction;
  QCInteractionPort *outputInteraction;
  QCBooleanPort *outputDown;
  QCBooleanPort *outputUp;
  QCBooleanPort *outputTap;
  QCBooleanPort *outputDrag;
  
  QCPatch *_cachedRenderingPatch;
  QCPatch *_sprite;
  QCPatch *_iterator;
}

- (BOOL)interactionEnabled;

@end
