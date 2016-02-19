/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

@interface FBOLiveFilePatchUI : QCInspector

@property (nonatomic, retain) NSString *filePath;
@property (assign) NSNumber *useAbsolutePath;
@property (assign) NSNumber *disableEmbedding;

- (BOOL)boolForKey:(NSString *)key;

@end
