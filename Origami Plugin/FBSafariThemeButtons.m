/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBSafariThemeButtons.h"

@implementation FBSafariThemeButtons

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8 {
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8 {
	return kQCPatchExecutionModeProvider;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8 {
	return kQCPatchTimeModeIdle;
}

- (void)enable:(QCOpenGLContext*)context {
  id value = self._renderingInfo.context.userInfo[@".QCView"];
  QCView *qcView = [value pointerValue];
  self.toolbarController = [FBSafariToolbarController controllerForQCView:qcView];
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
  [outputBack setBooleanValue:self.toolbarController.backDown];
  [outputForward setBooleanValue:self.toolbarController.forwardDown];
  
  return YES;
}

@end
