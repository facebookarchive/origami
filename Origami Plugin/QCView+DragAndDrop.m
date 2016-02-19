/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "QCView+DragAndDrop.h"
#import "NSObject+AssociatedObjects.h"

@implementation QCView (DragAndDrop)

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
  NSPasteboard *pboard = [sender draggingPasteboard];
  
  if ([[pboard types] containsObject:NSFilenamesPboardType]) {
    NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
    
    [self associateValue:@YES withKey:@"fb_isDragging"];
    [self associateValue:files withKey:@"fb_draggedFiles"];
    
    NSNumber *operationIndex = [self associatedValueForKey:@"fb_draggingOperation"];
    NSDragOperation dragOperation = operationIndex.unsignedIntegerValue;
    
    return dragOperation;
  }
  
  return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
  NSPasteboard *pboard = [sender draggingPasteboard];
  
  if ([[pboard types] containsObject:NSFilenamesPboardType]) {
    [self associateValue:[NSValue valueWithPoint:sender.draggingLocation] withKey:@"fb_draggingLocation"];
  }
  
  NSNumber *operationIndex = [self associatedValueForKey:@"fb_draggingOperation"];
  NSDragOperation dragOperation = operationIndex.unsignedIntegerValue;
  
  return dragOperation;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
  NSPasteboard *pboard = [sender draggingPasteboard];
  
  if ([[pboard types] containsObject:NSFilenamesPboardType]) {
    [self associateValue:@NO withKey:@"fb_isDragging"];
    [self associateValue:nil withKey:@"fb_draggingLocation"];
    [self associateValue:nil withKey:@"fb_draggedFiles"];
  }
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
  NSPasteboard *pboard = [sender draggingPasteboard];

  if ([[pboard types] containsObject:NSFilenamesPboardType]) {
    [self associateValue:@NO withKey:@"fb_isDragging"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FBDragCompleteNotification" object:self userInfo:nil];
  }
  
  return YES;
}

@end
