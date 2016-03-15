/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "DHAppleScriptPatch.h"
#import "NSAppleScript+FBAdditions.h"

@implementation DHAppleScriptPatch

- (id)initWithIdentifier:(id)identifier {
	if (self = [super initWithIdentifier:identifier]) {
    
  }
  
	return self;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)identifier {
	return kQCPatchExecutionModeProvider;
}

+ (BOOL)allowsSubpatchesWithIdentifier:(id)identifier {
	return NO;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)identifier {
	return kQCPatchTimeModeNone;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
  if (!(inputScript.wasUpdated || inputUpdateSignal.wasUpdated)) {
    return YES;
  }
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
    NSString *error = nil;
    id result = [NSAppleScript runScript:inputScript.stringValue error:&error];
    
    if ([result isKindOfClass:[NSArray class]]) {
      result = [[QCStructure alloc] initWithArray:result];
    } else if ([result isKindOfClass:[NSDictionary class]]) {
      result = [[QCStructure alloc] initWithDictionary:result];
    }
    
    outputResult.rawValue = (error) ? error : result;
  });

  return YES;
}

@end
