/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBFileUpdated.h"
#import "CDEvents.h"
#import "QCPatch+FBAdditions.h"
#import "NSString+RelativePath.h"

@interface FBFileUpdated ()
@property (retain, nonatomic) CDEvents *events;
@property (assign, nonatomic) NSDocument *document;
@property BOOL shouldSendUpdatePulse;
@end

@implementation FBFileUpdated

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8 {
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8 {
	return kQCPatchExecutionModeProvider;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8 {
	return kQCPatchTimeModeIdle;
}

- (BOOL)setup:(QCOpenGLContext *)context {
  self.document = [self fb_document];

  return [super setup:context];
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments
{
  if (outputUpdated.booleanValue) {
    outputUpdated.booleanValue = NO;
  }
  
  if (self.shouldSendUpdatePulse) {
    outputUpdated.booleanValue = YES;
    self.shouldSendUpdatePulse = NO;
  }
  
  if (inputPath.wasUpdated && ![inputPath.stringValue isEqualToString:@""]) {
    NSString *path = inputPath.stringValue;
    
    NSString *filePath = path;
    
    if (![path isAbsolutePath] && self.document.fileURL) {
      NSString *baseDirPath = [self.document.fileURL.path stringByDeletingLastPathComponent];
      filePath = [path absolutePathFromBaseDirPath:baseDirPath];
    }

    NSURL *url = [NSURL fileURLWithPath:filePath isDirectory:NO];

    if (url) {
      self.events = [[CDEvents alloc] initWithURLs:[NSArray arrayWithObject:url] block:^(CDEvents *watcher, CDEvent *event) {
        self.shouldSendUpdatePulse = YES;
      }];
    }
   
  }
  
  return YES;
}

@end
