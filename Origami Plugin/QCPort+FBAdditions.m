/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "QCPort+FBAdditions.h"

@implementation QCPort (FBAdditions)

- (NSArray *)fb_connectedPorts {
  NSMutableArray *connectedPorts = [NSMutableArray array];
  
  for (QCLink *connection in [self.parentPatch.parentPatch connections]) {
    if (connection.sourcePort == self) {
      [connectedPorts addObject:connection.destinationPort];
    } else if (connection.destinationPort == self) {
      [connectedPorts addObject:connection.sourcePort];
    }
  }
  
  return [NSArray arrayWithArray:connectedPorts];
}

- (BOOL)fb_isInputPort {
  return (self.direction == -1);
}

// GFNameForPort() equivalent
- (NSString *)fb_name {
  NSString *name = [[self userInfo] objectForKey:@"name"];
  
  if (name)
    return name;
  
  name = [[self attributes] objectForKey:@"name"];
  
  if (!name)
    name = [self key];
  
  return name;
}

@end
