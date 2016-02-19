/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "NSView+FBAdditions.h"

@implementation NSView (FBAdditions)

- (CGFloat)fb_pixelAlignedValue:(CGFloat)value {
  CGFloat scale = [self convertPointToBacking:NSMakePoint(1.0, 1.0)].x;
  return roundf(value * scale) / scale;
}

- (CGFloat)fb_pixelAlignedValueByCeiling:(CGFloat)value {
  CGFloat scale = [self convertPointToBacking:NSMakePoint(1.0, 1.0)].x;
  return ceilf(value * scale) / scale;
}

- (CGFloat)fb_pixelAlignedValueByFlooring:(CGFloat)value {
  CGFloat scale = [self convertPointToBacking:NSMakePoint(1.0, 1.0)].x;
  return floorf(value * scale) / scale;
}

- (NSRect)fb_pixelAlignedOrigin:(NSRect)rect {
  NSRect newRect = rect;
  newRect.origin.x = [self fb_pixelAlignedValue:newRect.origin.x];
  newRect.origin.y = [self fb_pixelAlignedValue:newRect.origin.y];
  return newRect;
}

@end
