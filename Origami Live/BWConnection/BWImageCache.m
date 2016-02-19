/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "BWImageCache.h"

#define kMaxPixelCost (640 * 640 * 150) // Around 240 MB. This should probably vary per device type

@implementation BWImageCache

+ (instancetype)imageCache {
  static BWImageCache *cache;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cache = [[self alloc] init];
  });
  return cache;
}

- (UIImage *)imageForKey:(NSString *)key {
  if (key)
    return [self objectForKey:key];

  return nil;
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key {
  if (!key)
    return;

  if (!image)
    [self removeObjectForKey:key];

  self.totalCostLimit = kMaxPixelCost;

  CGSize imageSize = image.size;
  [self setObject:image forKey:key cost:(imageSize.width * imageSize.height)];
}

@end
