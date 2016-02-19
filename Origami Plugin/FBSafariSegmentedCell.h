/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <Cocoa/Cocoa.h>
#import "FBSafariToolbarController.h"

@interface FBSafariSegmentedCell : NSSegmentedCell

@property (weak, nonatomic) FBSafariToolbarController *toolbarController;
@property BOOL downSegment;

@end
