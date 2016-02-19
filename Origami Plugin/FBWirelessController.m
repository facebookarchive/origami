/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBWirelessController.h"
#import "FBWirelessInPatch.h"
#import "FBWirelessOutPatch.h"
#import "NSObject+FBAdditions.h"
#import "QCPatch+FBAdditions.h"

static NSMutableDictionary *controllers; // Key: NSDocument pointer address  Value: FBWirelessController instance

@implementation FBWirelessController

+ (void)initialize
{
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    controllers = [[NSMutableDictionary alloc] init];
  });
}

+ (FBWirelessController *)controllerForPatch:(QCPatch *)patch {
  NSDocument *document = [patch fb_document];
  FBWirelessController *controller = [FBWirelessController controllerForDocument:document];
  
  return controller;
}

+ (FBWirelessController *)controllerForDocument:(NSDocument *)document {
  if (document == nil) {
    return nil;
  }
  
  NSString *pointerAddress = [NSString stringWithFormat:@"%p", document];
  FBWirelessController *controller;
  
  if ([controllers objectForKey:pointerAddress]) {
    controller = [controllers objectForKey:pointerAddress];
  } else {
    FBWirelessController *newController = [[FBWirelessController alloc] init];    
    [controllers setObject:newController forKey:pointerAddress];
    controller = newController;
  }
  
  return controller;
}

- (id)init {
    self = [super init];
    if (self) {
      self.keyedData = [NSMutableDictionary dictionary];
      self.keyedBroadcasters = [NSMutableDictionary dictionary];
    }
    return self;
}

@end
