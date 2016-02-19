/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

typedef enum {
  FBSerializationTypeAll,
  FBSerializationTypeChange
} FBSerializationType;

@interface FBDeviceRendererPatch : QCPatch {
  QCNumberPort *inputXPosition;
  QCNumberPort *inputYPosition;
  QCNumberPort *inputZPosition;
  QCNumberPort *inputXRotation;
  QCNumberPort *inputYRotation;
  QCNumberPort *inputZRotation;
  QCImagePort *inputImage;
  QCImagePort *inputMaskImage;
  QCNumberPort *inputWidth;
  QCNumberPort *inputHeight;
  QCColorPort *inputColor;
  QCNumberPort *inputAlpha;
  QCNumberPort *inputScale;
  QCStringPort *inputAttachedRII; // Deprecated. Not used anymore.
  QCIndexPort *inputIterationCount;
  QCIndexPort *inputIterationIndex;
  QCIndexPort *inputFrameNumber;

  uint32_t _patchID, _basePatchID;
  NSUInteger _cachedQueueIndex;
  uint32_t _parentRIIHash;
}

+ (void)setNeedsTreeSerialization;

@end
