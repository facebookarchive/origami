/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <UIKit/UIKit.h>

@interface BWOverlayView : UIView

@property (retain, nonatomic) NSMutableDictionary *touchDictionary;

- (void)clearTouches;

@end
