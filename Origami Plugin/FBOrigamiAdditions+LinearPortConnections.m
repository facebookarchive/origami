/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiAdditions+LinearPortConnections.h"
#import "FBOrigamiAdditions+Preferences.h"
#import "NSObject+FBAdditions.h"

@interface FBOrigamiAdditions ()
- (BOOL)original_drawConnection:(QCLink *)link fromPoint:(NSPoint)from toPoint:(NSPoint)to;
@end

@implementation FBOrigamiAdditions (LinearPortConnections)

- (void)setupLinearPortConnections {
  [self fb_swizzleInstanceMethod:@selector(drawConnection:fromPoint:toPoint:) forClassName:@"QCPatchView"];
}

- (void)drawConnection:(QCLink *)link fromPoint:(NSPoint)from toPoint:(NSPoint)to {
  if (!FBOrigamiAdditions.isLinearPortConnectionsEnabled) {
    [(QCPatchView *)self _drawConnection:link fromPort:[link sourcePort] point:from toPoint:to];
    return;
  }
  
  [[NSGraphicsContext currentContext] saveGraphicsState];
  
  NSBezierPath *path = [NSBezierPath bezierPath];
  [path moveToPoint:from];
  [path lineToPoint:to];
  [path setLineCapStyle:NSRoundLineCapStyle];
  [path setLineWidth:2.0];
  [[(QCPatchView *)self _colorForConnection:link] setStroke];
  [path stroke];
  
  [[NSGraphicsContext currentContext] restoreGraphicsState];
}

@end
