/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <Cocoa/Cocoa.h>

@interface FBPatchView : NSView

@property (weak) GFGraphView *graphView;

+ (NSImage *)imageForImageLoader:(QCPatch *)patch;
+ (NSRect)imageRectForActorSize:(NSSize)actorSize originalImageSize:(NSSize)originalImageSize;

@end
