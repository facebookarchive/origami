/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <SkankySDK/SkankySDK.h>
#import "FBSafariToolbarController.h"

@interface FBSafariTheme : QCPatch {
  QCStringPort *inputWindowTitle;
  QCStringPort *inputURL;
  QCImagePort *inputFavicon;
  QCBooleanPort *inputBackEnabled;
  QCBooleanPort *inputForwardEnabled;
}

@property (strong, nonatomic) FBSafariToolbarController *toolbarController;
@property (strong, nonatomic) NSToolbar *cachedToolbar;
@property (copy, nonatomic) NSString *cachedWindowTitle;
@property (weak, nonatomic) NSWindow *cachedViewerWindow;
@property NSWindowCollectionBehavior cachedCollectionBehavior;
@property NSToolbarDisplayMode cachedToolbarDisplayMode;

@end
