/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <SkankySDK/SkankySDK.h>

@interface QCImage (FBAdditions)

- (NSString *)fb_dataMD5; // Expensive MD5 hash of an archived QCImage object. Duplicate image patches will have the same fb_dataMD5 value.
- (NSString *)fb_providerMD5; // Cheap MD5 hash of the QCImageProvider. Duplicate image patches will have different fb_providerMD5 values.
- (NSData *)fb_imageData;

@end
