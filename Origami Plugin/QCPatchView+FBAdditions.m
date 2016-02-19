/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "QCPatchView+FBAdditions.h"
#import "QCPatch+FBAdditions.h"
#import "QCPort+FBAdditions.h"

static CGFloat kPatchPadding = 24.0;

@implementation QCPatchView (FBAdditions)

- (NSPoint)fb_positionForPatchWithPort:(QCPort *)newPort alignedToPort:(QCPort *)connectedPort {
  NSPoint newPosition = NSZeroPoint;
  
  QCPatch *newPatch = (QCPatch *)newPort.node;
  QCPatch *connectedPatch = (QCPatch *)connectedPort.node;
  
  QCPatchActor *newPatchActor = [self nodeActorForNode:newPatch];
  QCPatchActor *connectedPatchActor = [self nodeActorForNode:connectedPatch];
  
  NSSize newPatchActorSize = [newPatchActor sizeForNode:newPatch];
  NSSize connectedPatchActorSize = [connectedPatchActor sizeForNode:connectedPatch];
  
  NSValue *connectedPatchPositionValue = connectedPatch.userInfo[@"position"];
  newPosition = connectedPatchPositionValue.pointValue;
  
  if (newPort.fb_isInputPort)
    newPosition.x += connectedPatchActorSize.width + kPatchPadding;
  else
    newPosition.x -= newPatchActorSize.width + kPatchPadding;
  
  NSPoint pointForNewPort = [newPatchActor pointForPort:newPort inNode:newPatch bounds:NSMakeRect(0.0, 0.0, newPatchActorSize.width, newPatchActorSize.height)];
  newPosition.y -= pointForNewPort.y;
  
  NSPoint pointForConnectedPort = [connectedPatchActor pointForPort:connectedPort inNode:connectedPatch bounds:NSMakeRect(0.0, 0.0, connectedPatchActorSize.width, connectedPatchActorSize.height)];
  newPosition.y += pointForConnectedPort.y;
  
  return newPosition;
}

- (NSValue *)fb_positionValueForPatchWithPort:(QCPort *)newPort alignedToPort:(QCPort *)connectedPort {
  NSPoint position = [self fb_positionForPatchWithPort:newPort alignedToPort:connectedPort];
  return [NSValue valueWithPoint:position];
}

- (void)fb_setSelected:(BOOL)flag forPatch:(QCPatch *)patch {
  if (flag) {
    patch.userInfo[@".selected"] = [NSNumber numberWithBool:YES];
  } else {
    [patch.userInfo removeObjectForKey:@".selected"];
  }

  [[NSNotificationCenter defaultCenter] postNotificationName:@"GFGraphViewSelectionDidChangeNotification" object:self userInfo:nil];
}

- (BOOL)fb_addPatch:(QCPatch *)patch {
  BOOL success = [self.graph addNode:patch];
  
  if (success) {
    [self _deselectAll];
    [patch.userInfo _setNullForKey:@".selected"];
    [self _setFirstResponderNode:patch];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GFGraphViewSelectionDidChangeNotification" object:self userInfo:nil];
    [self _adjustFrame];
  }
  
  return success;
}

- (QCPatch *)fb_selectedPatch {
  QCPatch *graph = [self graph];
  
  if (((NSArray *)graph.selectedNodes).count > 0) {
    return graph.selectedNodes[0];
  }
  
  return nil;
}

@end
