/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "BWViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "BWDeviceInfoTransmitter.h"
#import "BWImageCache.h"
#import "BWOverlayView.h"

__attribute__((unused)) static CGFloat BWVCDegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};
__attribute__((unused)) static CGFloat BWVCRadiansToDegrees(CGFloat radians) {return radians * 180 / M_PI;};

@interface BWViewController () {
  dispatch_queue_t _queue;
}
@end

@implementation BWViewController

- (void)loadView
{
  if (self.nibName) {
    [super loadView];
  } else {
    self.view = self.overlayView = [[BWOverlayView alloc] initWithFrame:CGRectZero];
  }
}

#pragma mark View Manipulation

- (void)createViewHierarchyFromTree:(NSArray *)tree {
  [self traverseViewHierarchy:tree ofParent:nil];
}

- (void)traverseViewHierarchy:(NSArray *)hierarchy ofParent:(UIView *)parentView {
  for (NSDictionary *properties in hierarchy) {
    if (parentView == nil) {
      parentView = self.view;
    }

    UIView *view = [self newViewWithProperties:properties parent:parentView];
    [parentView addSubview:view];

    NSArray *children = properties[@"children"];
    if (children) {
      [self traverseViewHierarchy:children ofParent:view];
    }
  }
}

- (UIView *)newViewWithProperties:(NSDictionary *)properties parent:(UIView *)parentView {
  UIView *newView = [[UIView alloc] initWithFrame:CGRectZero];
  CALayer *newLayer = newView.layer;
  newLayer.anchorPoint = CGPointMake(0.5, 0.5);
  newLayer.masksToBounds = YES;
  newLayer.rasterizationScale = [UIScreen mainScreen].scale;
  [self applyPerspectiveToLayer:newLayer];

  NSString *viewID = properties[@"id"];

  [self setProperties:properties onView:newView parent:parentView viewID:viewID];

  (self.idsToViews)[viewID] = newView;

  return newView;
}

- (void)setProperties:(NSDictionary *)properties onView:(UIView *)view parent:(UIView *)parentView viewID:(NSString *)viewID {
  if (view == nil || properties.count == 0) {
    return;
  }

  CALayer *parentLayer = parentView.layer;
  CALayer *layer = view.layer;

  NSNumber *x = properties[@"x"];
  NSNumber *y = properties[@"y"];
  NSNumber *z = properties[@"z"];
  NSNumber *xRotation = properties[@"xRotation"];
  NSNumber *yRotation = properties[@"yRotation"];
  NSNumber *zRotation = properties[@"zRotation"];
  NSNumber *width = properties[@"width"];
  NSNumber *height = properties[@"height"];
  NSNumber *colorR = properties[@"colorR"];
  NSNumber *colorG = properties[@"colorG"];
  NSNumber *colorB = properties[@"colorB"];
  NSNumber *alpha = properties[@"alpha"];
  NSNumber *scale = properties[@"scale"];
  NSString *imageHash = properties[@"image"];
  NSString *maskImageHash = properties[@"maskImage"];
  NSArray *children = properties[@"children"];

  // Position
  if (x || y) {
    CGPoint newPosition = layer.position;

    if (x)
      newPosition.x = (parentLayer.bounds.size.width / 2) + (x.floatValue / self.screenScale);

    if (y)
      newPosition.y = (parentLayer.bounds.size.height / 2) - (y.floatValue / self.screenScale);

    layer.position = newPosition;
  }

  if (z) {
    layer.zPosition = z.floatValue;
  }

  // Bounds
  if (width || height) {
    CGRect newBounds = layer.bounds;

    if (width)
      newBounds.size.width = (width.floatValue / self.screenScale);

    if (height)
      newBounds.size.height = (height.floatValue / self.screenScale);

    // If the view has children, we need to reposition them so they're not anchored top left
    for (UIView *subview in view.subviews) {
      CALayer *sublayer = subview.layer;

      CGFloat offsetFromCenterX = sublayer.position.x - (layer.bounds.size.width / 2);
      CGFloat offsetFromCenterY = sublayer.position.y - (layer.bounds.size.height / 2); // maybe +

      CGPoint newPosition;
      newPosition.x = (newBounds.size.width / 2) + offsetFromCenterX;
      newPosition.y = (newBounds.size.height / 2) + offsetFromCenterY;
      sublayer.position = newPosition;
    }

    layer.bounds = newBounds;
  }

  // Resize mask
  if (x || y || width || height) {
    layer.mask.frame = layer.bounds;
  }

  // Image Hash
  if (imageHash) {
    if (![imageHash isEqualToString:@"0"] && ![imageHash isEqualToString:@""]) {
      [layer setValue:imageHash forKey:@"fb_imageHash"];
      UIImage *image = [[BWImageCache imageCache] imageForKey:imageHash];
      [self setImage:image onLayer:layer];
    } else {
      layer.contents = nil;
      [layer setValue:@"" forKey:@"fb_imageHash"];
    }
  }

  // Mask Image Hash
  if (maskImageHash) {
    if (![maskImageHash isEqualToString:@"0"] && ![maskImageHash isEqualToString:@""]) {
      [layer setValue:maskImageHash forKey:@"fb_maskImageHash"];
      UIImage *image = [[BWImageCache imageCache] imageForKey:maskImageHash];
      if (!layer.mask) {
        layer.mask = [CALayer layer];
        layer.masksToBounds = NO;
        layer.mask.frame = layer.bounds;
        [layer setValue:@YES forKey:@"fb_isMask"];
      }
      [self setImage:image onLayer:layer.mask];
    } else {
      layer.mask = nil;
      layer.masksToBounds = YES;
      [layer setValue:@"" forKey:@"fb_maskImageHash"];
    }
  }

  // Color - Assumes the other side sends all color components over whenever one changes
  BOOL isLayerGroup = (children.count > 0) || (view.subviews.count > 0);
  if (colorR && colorG && colorB && !isLayerGroup) {
    UIColor *color = [UIColor colorWithRed:colorR.floatValue green:colorG.floatValue blue:colorB.floatValue alpha:1.0];
    BOOL colorIsNotWhite = !((colorR.floatValue > 0.999) && (colorG.floatValue > 0.999) && (colorB.floatValue > 0.999));
    [layer setValue:color forKey:@"fb_color"];
    [layer setValue:@(colorIsNotWhite) forKey:@"fb_colorIsNotWhite"];

    NSString *hash = [layer valueForKey:@"fb_imageHash"];
    if (hash && ![hash isEqualToString:@""]) {
      UIImage *image = [[BWImageCache imageCache] imageForKey:hash];
      [self setImage:image onLayer:layer];
    } else {
      layer.backgroundColor = color.CGColor;
    }
  }

  // Transformation - Assumes the other side sends scale and all rotation components whenever one changes
  if (scale && xRotation && yRotation && zRotation) {
    CGFloat xRotationRadians = BWVCDegreesToRadians(xRotation.floatValue) * -1;
    CGFloat yRotationRadians = BWVCDegreesToRadians(yRotation.floatValue);
    CGFloat zRotationRadians = BWVCDegreesToRadians(zRotation.floatValue) * -1;

    CATransform3D transform = CATransform3DIdentity;
    transform = CATransform3DScale(transform, scale.floatValue, scale.floatValue, scale.floatValue);
    transform = CATransform3DRotate(transform, xRotationRadians, 1.0, 0.0, 0.0);
    transform = CATransform3DRotate(transform, yRotationRadians, 0.0, 1.0, 0.0);
    transform = CATransform3DRotate(transform, zRotationRadians, 0.0, 0.0, 1.0);
    layer.transform = transform;
  }

  // Opacity
  if (alpha) {
    layer.opacity = alpha.floatValue;
  }
}

- (void)applyChanges:(NSDictionary *)layers {
  for (NSString *viewID in layers.allKeys) {
    UIView *view = (self.idsToViews)[viewID];
    NSDictionary *properties = [layers objectForKey:viewID];
    [self setProperties:properties onView:view parent:view.superview viewID:viewID];
  }
}

- (void)setImage:(UIImage *)image withHash:(NSString *)imageHash layerKey:(NSString *)layerKey {
  if (image && imageHash && layerKey) {
    [[BWImageCache imageCache] setImage:[image copy] forKey:imageHash];

    UIView *view = self.idsToViews[layerKey];
    [self setImage:image onLayer:view.layer];
  }
}

- (void)setImage:(UIImage *)image onLayer:(CALayer *)layer {
  if (image && layer) {
    NSNumber *colorIsNotWhite = [layer valueForKey:@"fb_colorIsNotWhite"];
    NSNumber *isMask = [layer valueForKey:@"fb_isMask"];
    if (colorIsNotWhite.boolValue && !isMask.boolValue) {
      dispatch_async(_queue, ^{
        @autoreleasepool {
          // Tint image
          CIImage *imageToFilter = [[CIImage alloc] initWithCGImage:image.CGImage options:nil];

          UIColor *color = [layer valueForKey:@"fb_color"];
          CIImage *colorImage = [CIImage imageWithColor:[CIColor colorWithCGColor:color.CGColor]];

          [self.multiplyFilter setValue:imageToFilter forKey:kCIInputImageKey];
          [self.multiplyFilter setValue:colorImage forKey:kCIInputBackgroundImageKey];

          CIImage *outputImage = [self.multiplyFilter outputImage];

          // Set it on the layer
          CGImageRef ref = [self.context createCGImage:outputImage fromRect:outputImage.extent];

          dispatch_async(dispatch_get_main_queue(), ^{
            layer.contents = (__bridge id)ref;
            CGImageRelease(ref);
            layer.backgroundColor = [UIColor clearColor].CGColor;
          });
        }
      });
    } else {
      @autoreleasepool {
        layer.contents = (id)image.CGImage;
        layer.backgroundColor = [UIColor clearColor].CGColor;
      }
    }
  }
}

- (void)removeViewWithID:(NSString *)viewID {
  UIView *view = (self.idsToViews)[viewID];
  [view removeFromSuperview];

  [self.idsToViews removeObjectForKey:viewID];
}

- (void)removeAllViews {
  while (self.view.subviews.count > 0) {
    UIView *subview = self.view.subviews.lastObject;
    [subview removeFromSuperview];
  }

  self.idsToViews = [NSMutableDictionary dictionary];
}

- (void)applyPerspectiveToLayer:(CALayer *)layer {
  CATransform3D transform = CATransform3DIdentity;

  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    transform.m34 = 1.0 / -900; // Calibrated to a QC rendering context sized at 1024x768
  else
    transform.m34 = 1.0 / -280; // Calibrated to a QC rendering context sized at 640x960

  layer.sublayerTransform = transform;
}

#pragma mark View Controller

- (BOOL)prefersStatusBarHidden {
  return YES;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.screenScale = [[UIScreen mainScreen] scale];

  self.idsToViews = [NSMutableDictionary dictionary];

  self.context = [CIContext contextWithOptions:nil];
  self.multiplyFilter = [CIFilter filterWithName:@"CIMultiplyCompositing"];
  _queue = dispatch_queue_create("bwqueue", DISPATCH_QUEUE_SERIAL);
  dispatch_set_target_queue(_queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));

  [[BWDeviceInfoTransmitter sharedTransmitter] initialSetup];

  self.view.layer.backgroundColor = [UIColor blackColor].CGColor;

  [self applyPerspectiveToLayer:self.view.layer];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  } else {
    return YES;
  }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
  // Rotate the interface // Note: only want to do this to top level layers
  for (UIView *view in self.view.subviews) {
    CALayer *layer = view.layer;
    CGPoint newPosition = layer.position;
    newPosition.x -= (self.view.bounds.size.height - self.view.bounds.size.width) / 2;
    newPosition.y -= (self.view.bounds.size.width - self.view.bounds.size.height) / 2;
    layer.position = newPosition;
  }

  // Send the changed info to the Mac
  BOOL isPortrait = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]);
  UIScreen *screen = [UIScreen mainScreen];

  NSMutableDictionary *dataDict = [BWDeviceInfoTransmitter sharedTransmitter].deviceData;
  dataDict[@"isPortrait"] = @(isPortrait);
  dataDict[@"screenWidth"] = @(self.view.bounds.size.width * screen.scale);
  dataDict[@"screenHeight"] = @(self.view.bounds.size.height * screen.scale);
}

- (void)viewDidUnload {
  [self setOverlayView:nil];
  [super viewDidUnload];
}

@end
