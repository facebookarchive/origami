/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiAdditions.h"

@interface FBOrigamiAdditions (PluginLoading)

// This searches subfolders in standard QC patch search paths and loads patches found into QC.
- (void)loadPluginsInSubfolders;

@end
