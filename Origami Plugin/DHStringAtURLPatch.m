/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "DHStringAtURLPatch.h"
#import "QCPatch+FBAdditions.h"
#import "NSURL+FBAdditions.h"

@implementation DHStringAtURLPatch

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)identifier {
	return kQCPatchExecutionModeProcessor;
}

+ (BOOL)allowsSubpatchesWithIdentifier:(id)identifier {
	return NO;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)identifier {
	return kQCPatchTimeModeNone;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
  if (!(inputEnable.wasUpdated || inputURL.wasUpdated || inputUpdateSignal.wasUpdated)) {
    return YES;
  }
  
  outputString.stringValue = nil;
  outputDoneSignal.booleanValue = NO;
  
  if (!inputEnable.booleanValue) {
    return YES;
  }
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
    NSError *error;
    outputString.stringValue = [NSString stringWithContentsOfURL:[NSURL URLWithQuartzComposerLocation:inputURL.stringValue relativeToDocument:self.fb_document] encoding:NSUTF8StringEncoding error:&error];
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
      outputDoneSignal.booleanValue = YES;
    });
  });
  
  return YES;
}

@end
