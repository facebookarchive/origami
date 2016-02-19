/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <UIKit/UIKit.h>
@class BWOverlayView;

@interface BWViewController : UIViewController

@property (retain, nonatomic) CALayer *box;
@property (retain, nonatomic) IBOutlet BWOverlayView *overlayView;
@property (retain, nonatomic) NSMutableDictionary *idsToViews;
@property (retain, nonatomic) CIContext *context;
@property (retain, nonatomic) CIFilter *multiplyFilter;
@property CGFloat screenScale;

- (void)createViewHierarchyFromTree:(NSArray *)tree;
- (void)applyChanges:(NSDictionary *)layers;
- (void)removeViewWithID:(NSString *)viewID;
- (void)setImage:(UIImage *)image withHash:(NSString *)imageHash layerKey:(NSString *)layerKey;
- (void)removeAllViews;

@end
