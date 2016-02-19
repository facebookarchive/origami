/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "BWNUXViewController.h"

@implementation BWNUXViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  } else {
    return YES;
  }
}

- (BOOL)prefersStatusBarHidden {
  return YES;
}

- (IBAction)learnMore:(id)sender {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://origami.facebook.com"]];
}

@end
