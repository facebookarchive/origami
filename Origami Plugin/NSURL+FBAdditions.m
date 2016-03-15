/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "NSURL+FBAdditions.h"
#import "NSString+RelativePath.h"

@implementation NSURL (FBAdditions)

+ (NSURL *)URLWithQuartzComposerLocation:(NSString *)location relativeToDocument:(NSDocument *)document {
  NSURL *url = [NSURL URLWithString:location];
  
  if (!url.scheme.length) {
    location = [location stringByStandardizingPath];
    if (!location.isAbsolutePath && document.fileURL) {
      NSString *baseDirPath = [document.fileURL.path stringByDeletingLastPathComponent];
      location = [location absolutePathFromBaseDirPath:baseDirPath];
    }
    
    url = [NSURL fileURLWithPath:location];
  }
  
  return url;
}

#pragma clang diagnostic ignored "-Wdeprecated-declarations"

+ (NSURL *)URLWithEventDescriptor:(NSAppleEventDescriptor *)appleEventDescriptor {
  unsigned int theSize = (unsigned int)AEGetDescDataSize([appleEventDescriptor aeDesc]);
  Handle aliasHandle = NewHandle(theSize);
  HLock(aliasHandle);
  AEGetDescData([appleEventDescriptor aeDesc], *aliasHandle, theSize);
  HUnlock(aliasHandle);
  
  NSURL *url = nil;
  FSRef theTarget;
  Boolean theWasChanged;
  if (FSResolveAlias(NULL, (AliasHandle)aliasHandle, &theTarget, &theWasChanged) == noErr) {
    url = (NSURL *)CFBridgingRelease(CFURLCreateFromFSRef(kCFAllocatorDefault, &theTarget));
  }
  
  DisposeHandle(aliasHandle);
  return url;
}

@end
