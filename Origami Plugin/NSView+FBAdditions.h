/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <Cocoa/Cocoa.h>

@interface NSView (FBAdditions)

- (CGFloat)fb_pixelAlignedValue:(CGFloat)value;
- (CGFloat)fb_pixelAlignedValueByCeiling:(CGFloat)value;
- (CGFloat)fb_pixelAlignedValueByFlooring:(CGFloat)value;
- (NSRect)fb_pixelAlignedOrigin:(NSRect)rect;

@end
