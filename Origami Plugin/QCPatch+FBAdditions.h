/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <SkankySDK/SkankySDK.h>

@interface QCPatch (FBAdditions)

- (NSDocument *)fb_document;
- (QCPatch *)fb_rootPatch;

- (QCPatchActor *)fb_actor;
- (NSSize)fb_actorSize;
- (NSSize)fb_actorSizeInKeyPatchView;
- (NSSize)fb_cachedActorSize; // Only invalidates on patch name change, not on port name change.
- (NSPoint)fb_actorPosition;
- (void)fb_setActorPosition:(NSPoint)position;

- (NSString *)fb_name;
- (NSString *)fb_classNameForNode;
- (NSString *)fb_className;

@end
