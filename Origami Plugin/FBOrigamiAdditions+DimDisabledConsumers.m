/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiAdditions+DimDisabledConsumers.h"
#import "NSObject+FBAdditions.h"

@interface FBOrigamiAdditions ()
- (CGColorRef)original__overlayColorForNode:(id)fp8 view:(NSView*)view;
- (NSColor*)original__colorForNode:(GFNode*)node;
@end

@implementation FBOrigamiAdditions (DimDisabledConsumers)

- (void)setupDimDisabledConsumers {
  [self fb_swizzleInstanceMethod:@selector(_overlayColorForNode:view:) forClassName:@"QCPatchActor"];
  [self fb_swizzleInstanceMethod:@selector(_colorForNode:) forClassName:@"QCPatchActor"];
}

- (CGColorRef)_overlayColorForNode:(GFNode *)node view:(NSView *)view {
  CGColorRef color = [self original__overlayColorForNode:node view:view];
  
  if ([node respondsToSelector:@selector(_enableInput)]) {
    if ([[(QCPatch *)node _enableInput] isKindOfClass:NSClassFromString(@"QCBooleanPort")]) {
      QCBooleanPort *port = [(QCPatch *)node _enableInput];
      
      if ([port booleanValue] == NO) {
        color = CGColorCreateGenericRGB(255.0/255.0, 255.0/255.0, 255.0/255.0, 0.01);
      }
    }
  }
  
  return color;
}

- (NSColor*)_colorForNode:(GFNode*)node {
  NSColor *color = [self original__colorForNode:node];
  
  if ([node respondsToSelector:@selector(_enableInput)]) {
    if ([[(QCPatch *)node _enableInput] isKindOfClass:NSClassFromString(@"QCBooleanPort")]) {
      QCBooleanPort *port = [(QCPatch *)node _enableInput];
      
      if ([port booleanValue] == NO) {
        color = [NSColor colorWithCalibratedRed:0.392 green:0.47 blue:0.71 alpha:0.75];
      }
    }
  }
  
  return color;
}

@end
