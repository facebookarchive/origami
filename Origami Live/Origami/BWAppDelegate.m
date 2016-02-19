/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "BWAppDelegate.h"

#import <BWConnection/BWDeviceInfoTransmitter.h>
#import <BWConnection/BWOverlayView.h>
#import <BWConnection/BWViewController.h>

#import <FBExceptionHandler/FBBreakpadExceptionHandler.h>

#import "BWExceptionHandlerProvider.h"
#import "BWNUXViewController.h"

@interface BWAppDelegate () <BWDeviceInfoTransmitterDelegate>

@end

@implementation BWAppDelegate

@synthesize window = _window;
@synthesize sceneController = _sceneController;
@synthesize nuxController = _nuxController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  application.statusBarHidden = YES;
  application.idleTimerDisabled = YES;

  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
      self.sceneController = [[BWViewController alloc] initWithNibName:@"BWViewController_iPhone" bundle:nil];
  } else {
      self.sceneController = [[BWViewController alloc] initWithNibName:@"BWViewController_iPad" bundle:nil];
  }

  self.nuxController = [[BWNUXViewController alloc] initWithNibName:@"BWNUXViewController" bundle:nil];

  [[BWDeviceInfoTransmitter sharedTransmitter] setDelegate:self];
  [[BWDeviceInfoTransmitter sharedTransmitter] setMainViewController:self.sceneController];

  self.window.rootViewController = self.nuxController;
  [self.window makeKeyAndVisible];

//  FBBreakpadExceptionHandler *exceptionHandler = [BWExceptionHandlerProvider provideConfiguredExceptionHandler];
//  [exceptionHandler send];

  return YES;
}

- (void)setConnected:(BOOL)flag {
  self.window.rootViewController = flag ? self.sceneController : self.nuxController;
}

- (void)applicationWillResignActive:(UIApplication *)application {
  [self.sceneController.overlayView clearTouches]; // Clear touches after multitasking gestures are used
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  [[BWDeviceInfoTransmitter sharedTransmitter] listen];
}

#pragma mark - BWDeviceInfoTransmitterDelegate

- (void)deviceInfoTransmitterDidConnect:(BWDeviceInfoTransmitter *)transmitter {
  [self setConnected:YES];
}

- (void)deviceInfoTransmitterDidDisconnect:(BWDeviceInfoTransmitter *)transmitter {
  [self setConnected:NO];
}


@end
