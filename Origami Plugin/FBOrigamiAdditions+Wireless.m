/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiAdditions+Wireless.h"
#import "NSObject+FBAdditions.h"
#import "FBWirelessInPatch.h"
#import "FBWirelessOutPatch.h"

@interface FBOrigamiAdditions ()
- (BOOL)original_pointInConsumerOrderRect:(NSPoint)rect inNode:(id)node bounds:(NSRect)bounds;
- (void)original__drawNode:(id)node bounds:(NSRect)bounds inContext:(CGContextRef)c;
@end

@implementation FBOrigamiAdditions (Wireless)

- (void)setupWireless {
  [self fb_swizzleInstanceMethod:@selector(pointInConsumerOrderRect:inNode:bounds:) forClassName:@"QCPatchActor"];
  [self fb_swizzleInstanceMethod:@selector(_drawNode:bounds:inContext:) forClassName:@"QCPatchActor"];
}

// Stop the layer order popup from appearing when clicking the right side of the wireless brodcasters
- (BOOL)pointInConsumerOrderRect:(NSPoint)rect inNode:(id)node bounds:(NSRect)bounds {
  BOOL flag = [self original_pointInConsumerOrderRect:rect inNode:node bounds:bounds];
  
  if ([node isMemberOfClass:[FBWirelessInPatch class]]) {
    flag = NO;
  }
  
  return flag;
}

// Draw the radio wave icons on the wireless patches
- (void)_drawNode:(id)node bounds:(NSRect)bounds inContext:(CGContextRef)c {
  [self original__drawNode:node bounds:bounds inContext:c];
  
  BOOL isWirelessIn = [node isMemberOfClass:[FBWirelessInPatch class]];
  BOOL isWirelessOut = [node isMemberOfClass:[FBWirelessOutPatch class]];
  
  if (isWirelessIn || isWirelessOut) {
    CGPoint unitPoint = CGPointMake(1.0, 1.0);
    CGPoint devicePoint = CGContextConvertPointToDeviceSpace(c, unitPoint);
    CGFloat scale = devicePoint.x;
    
    NSBundle *bundle = [NSBundle bundleForClass:[FBWirelessController class]];
    NSString *type = isWirelessIn ? @"Broadcast" : @"Receive";
    NSString *size = (scale > 1.1) ? @"4x" : @"1x";
    NSString *path = [bundle pathForImageResource:[NSString stringWithFormat:@"%@%@",type,size]];
    NSImage *image = [[NSImage alloc] initByReferencingFile:path];
    
    NSGraphicsContext *g = [NSGraphicsContext currentContext];
    CGImageRef img = [image CGImageForProposedRect:&bounds context:g hints:nil];
    
    CGRect imgRect = CGRectZero;
    imgRect.size = CGSizeMake(30, 30);
    imgRect.origin = CGPointMake(isWirelessIn ? (bounds.size.width - imgRect.size.width) + 12 : -7, roundf((bounds.size.height / 2) - (imgRect.size.height / 2)) + 2);
    
    CGContextDrawImage(c, imgRect, img);
  }
}

@end
