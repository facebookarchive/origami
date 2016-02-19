/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <SkankySDK/SkankySDK.h>

@interface QCPatchView (FBAdditions)

- (NSPoint)fb_positionForPatchWithPort:(QCPort *)newPort alignedToPort:(QCPort *)port;
- (NSValue *)fb_positionValueForPatchWithPort:(QCPort *)newPort alignedToPort:(QCPort *)connectedPort;
- (void)fb_setSelected:(BOOL)flag forPatch:(QCPatch *)patch;

// -[GFGraphView _addNode:atPosition:] equivalent but without the positioning code.
- (BOOL)fb_addPatch:(QCPatch *)patch;

// Makes debugging with F-Script Anywhere a bit easier
- (QCPatch *)fb_selectedPatch;

@end
