/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <Foundation/Foundation.h>

typedef enum {
  FBInputTypeMouse,
  FBInputTypeTouch
} FBInputType;

@interface FBOInteractionController : NSObject

@property NSSize viewerSize;
@property (strong, nonatomic) NSMutableDictionary *hitPatches; // A set of hit patches for each iteration
@property (strong, nonatomic) NSMutableDictionary *downPoints; // A down point for each iteration
@property (strong, nonatomic) NSMutableDictionary *lastTouchPoints; // A point for each iteration

+ (FBOInteractionController *)controllerForPatch:(QCPatch *)patch;
- (BOOL)hitTestGraphWithPoint:(NSPoint)point forInputType:(FBInputType)inputType iteration:(NSUInteger)iteration;
- (BOOL)hitTestPatch:(QCPatch *)targetPatch withPoint:(NSPoint)point forInputType:(FBInputType)inputType iteration:(NSUInteger)iteration;
- (BOOL)patchIsUberSprite:(QCPatch *)patch;

@end
