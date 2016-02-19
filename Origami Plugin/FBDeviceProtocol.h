/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <Foundation/Foundation.h>
#include <stdint.h>

static const int FBProtocolIPv4PortNumber = 2345;

typedef enum {
  FBFrameTypeDeviceInfo = 100,
  FBFrameTypeTextMessage = 101,
  FBFrameTypeSensorData = 102,
  FBFrameTypeLayerTree = 103,
  FBFrameTypeLayerAdditions = 104,
  FBFrameTypeLayerChanges = 105,
  FBFrameTypeLayerRemovals = 106,
  FBFrameTypeImage = 107,
  FBFrameTypeVibration = 108,
  FBFrameTypeLayerRemoval = 109,
  FBFrameTypeImageReceived = 110,
} FBFrameType;
