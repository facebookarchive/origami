/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "BWOverlayView.h"

#import "BWDeviceInfoTransmitter.h"

@interface BWOverlayView ()
- (void)sendTouches;
@end

@implementation BWOverlayView
@synthesize touchDictionary = _touchDictionary;

- (id)init
{
  self = [super init];
  self.touchDictionary = [NSMutableDictionary dictionary];
  return self;
}

- (void)awakeFromNib {
  self.touchDictionary = [NSMutableDictionary dictionary];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  for (UITouch *touch in touches.allObjects) {
    NSString *pointerAddress = [NSString stringWithFormat:@"%p", touch];

    (self.touchDictionary)[pointerAddress] = touch;
  }

  [self sendTouches];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [self endedOrCancelled:touches];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  [self endedOrCancelled:touches];
}

- (void)endedOrCancelled:(NSSet *)touches {
  [self sendTouches];

  for (UITouch *touch in touches.allObjects) {
    NSString *pointerAddress = [NSString stringWithFormat:@"%p", touch];

    [self.touchDictionary removeObjectForKey:pointerAddress];
  }

  [self performSelector:@selector(sendTouches) withObject:nil afterDelay:0];
}

- (void)sendTouches {
  [BWDeviceInfoTransmitter sharedTransmitter].touches = self.touchDictionary;
}

- (void)clearTouches {
  [self.touchDictionary removeAllObjects];

  [self sendTouches];
}

@end
