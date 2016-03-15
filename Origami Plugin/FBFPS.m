/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBFPS.h"

@interface FBFPS () {
  QCView *_qcView;
  double _previousTime;
}
@end

@implementation FBFPS

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8 {
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8 {
	return kQCPatchExecutionModeProvider;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8 {
	return kQCPatchTimeModeIdle;
}

- (void)enable:(QCOpenGLContext *)context {
  id value = self._renderingInfo.context.userInfo[@".QCView"];
  _qcView = [value pointerValue];
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
  if ([_qcView respondsToSelector:@selector(averageFPS)]) {
    [outputFPS setDoubleValue:_qcView.averageFPS];
    
    if (roundf(time * 2.0) / 2.0 != roundf(_previousTime * 2.0) / 2.0) {  // Execute every 0.5s
      [outputFPSString setStringValue:[NSString stringWithFormat:@"%.2f FPS",_qcView.averageFPS]];
    }
  }
  
  _previousTime = time;
  
  return YES;
}

@end
