/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOInteractionController.h"
#import "QCPatch+FBAdditions.h"
#import "NSDocument+FBAdditions.h"
#import "NSObject+AssociatedObjects.h"
#import "FBOInteractionPatch.h"

#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)
#define fequalzero(a) (fabs(a) < FLT_EPSILON)

CGFloat FBDegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};
CGFloat FBRadiansToDegrees(CGFloat radians) {return radians * 180 / M_PI;};

static NSMutableDictionary *controllers; // Key: NSDocument pointer address  Value: FBOInteractionController instance

@interface FBOInteractionController ()
@property (weak, nonatomic) NSDocument *document;
@property BOOL shouldKeepTraversing;
@end

@implementation FBOInteractionController

+ (void)initialize
{
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    controllers = [[NSMutableDictionary alloc] init];
  });
}

+ (FBOInteractionController *)controllerForPatch:(QCPatch *)patch {
  NSDocument *document = [patch fb_document];
  FBOInteractionController *controller = [FBOInteractionController controllerForDocument:document];
  
  return controller;
}

+ (FBOInteractionController *)controllerForDocument:(NSDocument *)document {
  if (document == nil) {
    return nil;
  }
  
  NSString *pointerAddress = [NSString stringWithFormat:@"%p", document];
  FBOInteractionController *controller;
  
  if ([controllers objectForKey:pointerAddress]) {
    controller = [controllers objectForKey:pointerAddress];
  } else {
    FBOInteractionController *newController = [[FBOInteractionController alloc] init];
    [controllers setObject:newController forKey:pointerAddress];
    controller = newController;
    controller.document = document;
    controller.hitPatches = [NSMutableDictionary dictionary];
    controller.downPoints = [NSMutableDictionary dictionary];
    controller.lastTouchPoints = [NSMutableDictionary dictionary];
  }
  
  return controller;
}

- (BOOL)hitTestPatch:(QCPatch *)targetPatch withPoint:(NSPoint)point forInputType:(FBInputType)inputType iteration:(NSUInteger)iteration {
  BOOL devicePatchWasHit = NO;
  NSNumber *iterationKey = @(iteration);
  NSMutableArray *hitPatches = self.hitPatches[iterationKey];
  
  if (inputType == FBInputTypeMouse) {
    QCPatch *topPatch = hitPatches[0];
    if ([self patchIsDevice:topPatch] && topPatch._enabled) {
      point = [self transformPoint:point toDevicePatch:hitPatches[0]];
      devicePatchWasHit = YES;
    }
  }
  
  for (int i = devicePatchWasHit; i < hitPatches.count; i++) {
    QCPatch *sprite = hitPatches[i];
    point = [self transformPoint:point toSprite:sprite];
    BOOL pointInSprite = [self hitTestPoint:point inSize:[self sizeForSprite:sprite]];
    
    if (sprite == targetPatch || !pointInSprite) {
      return pointInSprite;
    }
  }
  
  return NO;
}

- (BOOL)hitTestGraphWithPoint:(NSPoint)point forInputType:(FBInputType)inputType iteration:(NSUInteger)iteration {
  QCPatch *rootPatch = self.document.fb_graph.fb_rootPatch;
  NSNumber *iterationKey = @(iteration);
  
  self.hitPatches[iterationKey] = [NSMutableArray array];
  self.shouldKeepTraversing = YES;
  [self traverseSubpatchesOfPatch:rootPatch withPoint:point inputType:inputType successArray:self.hitPatches[iterationKey]];
  
  return (((NSMutableArray *)self.hitPatches[iterationKey]).count > 0);
}

- (void)traverseSubpatchesOfPatch:(QCPatch *)parentPatch withPoint:(NSPoint)point inputType:(FBInputType)inputType successArray:(NSMutableArray *)hitPatches {
  BOOL hitTestSuccessful = NO;
  
  for (QCPatch *aPatch in [parentPatch.consumerSubpatches reverseObjectEnumerator]) {
    if (!self.shouldKeepTraversing) {
      return;
    }
    
    QCPatch *patch = aPatch;
    
    // If the patch is a device patch, traverse the connected RII.
    if ([self patchIsDevice:patch] && patch._enabled) {
      QCImagePort *imagePort = [patch portForKey:@"Screen_Image"];
      
      if (!imagePort)
        imagePort = [patch portForKey:@"Screen"];
      
      if (!imagePort)
        imagePort = [patch portForKey:@"Image"];
      
      QCRenderInImage *riiPatch = [imagePort.imageValue metadataForKey:@"FBAttachedRII"];

      if (riiPatch) {
        if (inputType == FBInputTypeMouse) {
          [hitPatches addObject:patch];
          point = [self transformPoint:point toDevicePatch:patch];
        }
        
        [self traverseSubpatchesOfPatch:riiPatch withPoint:point inputType:inputType successArray:hitPatches];
      }
    }
    // If the patch is an Uber Sprite and the hit test succeeds, consider the sprite hit and traverse the connected RII.
    if ([self patchIsUberSprite:patch] && [self shouldHitTestSprite:patch]) {
      CGPoint newPoint = [self transformPoint:point toSprite:patch];
      if ([self hitTestPoint:newPoint inSize:[self sizeForSprite:patch]]) {
        hitTestSuccessful = YES;
        [hitPatches addObject:patch];
        
        QCImagePort *imagePort = [patch portForKey:@"Image"];
        QCRenderInImage *riiPatch = [imagePort.imageValue metadataForKey:@"FBAttachedRII"];
        if (riiPatch)
          [self traverseSubpatchesOfPatch:riiPatch withPoint:newPoint inputType:inputType successArray:hitPatches];
      }
    }
    // Otherwise, traverse its subpatches.
    else {
      if (patch._enabled && patch.subpatches.count > 0) {
        [self traverseSubpatchesOfPatch:patch withPoint:point inputType:inputType successArray:hitPatches];
      }
    }
    
    if (hitTestSuccessful) {
      self.shouldKeepTraversing = NO;
    }
  }
}

- (NSPoint)transformPoint:(NSPoint)point toSprite:(QCPatch *)sprite {
  double positionX = 0.0;
  double positionY = 0.0;
  
  if ([sprite.attributes[@"name"] hasPrefix:@"Uber Sprite"] || [sprite.userInfo[@"name"] hasPrefix:@"Uber Sprite"]) {
    positionX = [[sprite portForKey:@"X_Position"] doubleValue];
    positionY = [[sprite portForKey:@"Y_Position"] doubleValue];
  } else { // Sprite is a Layer patch
    // To get the position of the Layer patch with the anchor position applied (calculated inside of the Layer patch) we need to know the position the sprite is being set to in pixels. To do this, we assume the sprite is inside a macro patch with its position provided in pixels with these exact port keys.
    
    for (QCPatch *subpatch in sprite.consumerSubpatches) {
      QCNumberPort *xPort = [subpatch portForKey:@"inputX_proxy_1"];
      QCNumberPort *yPort = [subpatch portForKey:@"inputY_proxy_1"];
      
      if (xPort && yPort) {
        positionX = xPort.doubleValue;
        positionY = yPort.doubleValue;
      }
    }
  }

  double angle = [[sprite portForKey:@"Z_Rotation"] doubleValue];
  double scale = [[sprite portForKey:@"Scale"] doubleValue];

  // Work around "CGAffineTransformInvert: singular matrix" bug when scale is 0.
  if (fequalzero(scale)) {
    scale = 0.00001;
  }
  
  CGAffineTransform transform = CGAffineTransformIdentity;
  transform = CGAffineTransformTranslate(transform, positionX, positionY);
  transform = CGAffineTransformRotate(transform, FBDegreesToRadians(angle));
  transform = CGAffineTransformScale(transform, scale, scale);
  transform = CGAffineTransformInvert(transform);
  point = CGPointApplyAffineTransform(point, transform);
  
  return point;
}

- (NSPoint)transformPoint:(NSPoint)point toDevicePatch:(QCPatch *)patch {
  CGFloat scale = 1.0;
  CGFloat counterScale = 1.0;
  
  for (QCPatch *subpatch in patch.consumerSubpatches) {
    // The patch the scale is applied to in the Phone / Device patch must be named "Screen" for this to work
    if ([subpatch.attributes[@"name"] hasPrefix:@"Screen"] || [subpatch.userInfo[@"name"] hasPrefix:@"Screen"]) {
      QCNumberPort *scalePort = [subpatch portForKey:@"Scale"];
      QCNumberPort *counterScalePort = [subpatch portForKey:@"Counter_Scale"];

      if (scalePort)
        scale = scalePort.doubleValue;
      
      if (counterScalePort)
        counterScale = counterScalePort.doubleValue;
      
      break;
    }
  }
  
  CGFloat targetScale = scale * counterScale;
  CGAffineTransform transform = CGAffineTransformMakeScale(1 / targetScale, 1 / targetScale);
  point = CGPointApplyAffineTransform(point, transform);
  
  return point;
}

- (BOOL)hitTestPoint:(NSPoint)point inSize:(NSSize)size {
  return (point.x > (-size.width / 2) && point.x < (size.width / 2) && point.y > (-size.height / 2) && point.y < (size.height / 2));
}

- (NSSize)sizeForSprite:(QCPatch *)sprite {
  NSSize size = NSZeroSize;
  size.width = [[sprite portForKey:@"Width"] doubleValue];
  size.height = [[sprite portForKey:@"Height"] doubleValue];

  if (fequalzero(size.width) || fequalzero(size.height)) {
    QCImage *image = [[sprite portForKey:@"Image"] imageValue];
    size = image.bounds.size;
  }
  
  return size;
}

- (BOOL)shouldHitTestSprite:(QCPatch *)sprite {
  QCNumberPort *alphaPort = [sprite portForKey:@"Alpha"];
  
  BOOL transparent = alphaPort && alphaPort.doubleValue < 0.00001;
  BOOL disabled = !sprite._enabled;
  BOOL interactionDisabled = NO;
  
  QCInteractionPort *interactionPort = [sprite portForKey:@"Mouse_Interaction"];
  
  if (!interactionPort)
    interactionPort = [sprite portForKey:@"Interaction"];
  
  FBOInteractionPatch *interactionPatch = interactionPort.value;
  
  if ([interactionPatch respondsToSelector:@selector(interactionEnabled)]) {
    interactionDisabled = !interactionPatch.interactionEnabled;
  }
  
  return !(transparent || disabled || interactionDisabled);
}

- (BOOL)patchIsDevice:(QCPatch *)patch {
  return [patch.attributes[@"name"] hasPrefix:@"Phone"] || [patch.attributes[@"name"] hasPrefix:@"/phone"] || [patch.userInfo[@"name"] hasPrefix:@"Phone"] ||
         [patch.attributes[@"name"] hasPrefix:@"Device"] || [patch.attributes[@"name"] hasPrefix:@"/device"] || [patch.userInfo[@"name"] hasPrefix:@"Device"];
}

- (BOOL)patchIsUberSprite:(QCPatch *)patch {
  return [patch.attributes[@"name"] hasPrefix:@"Layer"] || [patch.userInfo[@"name"] hasPrefix:@"Layer"] ||
         [patch.attributes[@"name"] hasPrefix:@"Uber Sprite"] || [patch.userInfo[@"name"] hasPrefix:@"Uber Sprite"];
}


@end
