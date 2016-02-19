/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <Foundation/Foundation.h>

@interface FBTextObject : NSObject

@property (strong, nonatomic) NSTextStorage *textStorage;
@property (strong, nonatomic) NSLayoutManager *layoutManager;
@property (strong, nonatomic) NSTextContainer *textContainer;
@property NSRange glyphRange;

@end
