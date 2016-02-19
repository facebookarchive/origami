/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBDragAndDropPatch.h"
#import "NSObject+AssociatedObjects.h"
#import "QCView+FBAdditions.h"

@interface FBDragAndDropPatch ()
@property (weak, nonatomic) QCView *qcView;
@property BOOL fireDropSignal;
@end

@implementation FBDragAndDropPatch

- (id)initWithIdentifier:(id)fp8 {
	if (self = [super initWithIdentifier:fp8]) {
    inputCursor.maxIndexValue = 2;
    inputCursor.indexValue = 1;
  }
  
	return self;
}

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8 {
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8 {
	return kQCPatchExecutionModeProvider;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8 {
	return kQCPatchTimeModeNone;
}

- (void)enable:(QCOpenGLContext*)context {
  id value = self._renderingInfo.context.userInfo[@".QCView"];
  self.qcView = (QCView *)[value pointerValue];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_dragComplete:) name:@"FBDragCompleteNotification" object:self.qcView];

  [self.qcView registerForDraggedTypes:@[NSFilenamesPboardType]];
}

- (void)disable:(QCOpenGLContext*)context {
  [self.qcView unregisterDraggedTypes];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"FBDragCompleteNotification" object:self.qcView];
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
  if (inputCursor.wasUpdated) {
    [self.qcView associateValue:@(inputCursor.indexValue) withKey:@"fb_draggingOperation"];
  }
  
  if (outputDropSignal.booleanValue)
    outputDropSignal.booleanValue = NO;
  
  if (self.fireDropSignal) {
    outputDropSignal.booleanValue = YES;
    self.fireDropSignal = NO;
  }
  
  NSArray *files = [self.qcView associatedValueForKey:@"fb_draggedFiles"];
  if (files.count > 1) {
    outputPath.rawValue = [[QCStructure alloc] initWithArray:files];
  } else if (files.count == 1) {
    outputPath.rawValue = files[0];
  } else {
    outputPath.rawValue = nil;
  }
  
  NSValue *location = [self.qcView associatedValueForKey:@"fb_draggingLocation"];
  if (location) {
    NSPoint point = location.pointValue;
    NSSize viewerSize = self.qcView.frame.size;
    CGFloat backingScale = self.qcView.fb_backingScale;
    outputX.doubleValue = (point.x - viewerSize.width / 2.0) * backingScale;
    outputY.doubleValue = (point.y - viewerSize.height / 2.0) * backingScale;
  } else {
    outputX.doubleValue = 0;
    outputY.doubleValue = 0;
  }
  
  NSNumber *dragging = [self.qcView associatedValueForKey:@"fb_isDragging"];
  if (dragging) {
    outputDragging.booleanValue = dragging.boolValue;
  }
  
  return YES;
}

- (void)_dragComplete:(NSNotification *)notif {
  self.fireDropSignal = YES;
}

@end
