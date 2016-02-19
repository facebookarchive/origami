/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <UIKit/UIKit.h>

@class BWViewController, BWNUXViewController;

@interface BWAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) BWViewController *sceneController;
@property (strong, nonatomic) BWNUXViewController *nuxController;

- (void)setConnected:(BOOL)flag;

@end
