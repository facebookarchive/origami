/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBODynamicPortsPatch.h"

@interface FBOLiveFilePatch : FBODynamicPortsPatch {
  QCStringPort *inputPath;
  QCImagePort *outputImage;
}

@property (assign) BOOL fileFound;
@property (assign) BOOL useAbsolutePath;
@property (assign, nonatomic) BOOL disableEmbedding;

@property (nonatomic) NSString *filePath;
@property (nonatomic) QCImage *cachedImage;
@property (strong, nonatomic) NSImage *cachedNSImage;

- (void)setPathString:(NSString *)path;

@end