/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiAdditions+RenderInImage.h"
#import "NSObject+FBAdditions.h"
#import "NSObject+AssociatedObjects.h"
#import "NSMenu+FBAdditions.h"
#import "GRPHookMethod.h"
#import <OpenGL/gl.h>
#import <OpenGL/CGLMacro.h>

static NSMutableDictionary *kOrigamiLayerGroupAttributes;
static NSMutableDictionary *kOrigamiLayerGroupXMLAttributes;

@interface FBOrigamiAdditions ()
- (BOOL)original_execute:(QCOpenGLContext*)context time:(double)time arguments:(NSDictionary*)args;
@end

@implementation FBOrigamiAdditions (RenderInImage)

- (void)setupRenderInImageHacks {
  // Swizzle RII images so we can get a reference to the RII from Layer
  [self fb_swizzleInstanceMethod:@selector(execute:time:arguments:) forClassName:@"QCRenderInImage"];

  // Auto-clear Layer Group patches
  GRPHookMethod(NSClassFromString(@"QCRenderInImage"), @selector(executeSubpatches:arguments:), ^(QCRenderInImage *self, double arg1, id arg2) {
    if (self.userInfo[@"fb_isLayerGroup"] && self.noFeedback && self._enabled) {
      QCCGLContext *context = [(QCOpenGLContext *)self._renderingInfo.context openGLContext];
      CGLContextObj cgl_ctx = context.CGLContextObj;
      glClearColor(0.0, 0.0, 0.0, 0.0);
      glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    }

    return GRPCallOriginal(arg1,arg2);
  });

  // Support having a Layer Group patch in the library that gets swapped out with a Render in Image once added to a composition. This uses our dummy FBOLayerGroup class.
  [self renameToLayerGroup];
  
  // Contextual menu to convert from Render in Image to Layer Group
  [self addConvertToLayerGroupMenuItem];
}

#pragma mark Rename to Layer Group

- (void)renameToLayerGroup {
  GRPHookMethod(NSClassFromString(@"QCNodeManager"), @selector(instantiateNodeWithName:), ^(QCNodeManager *self, NSString *name) {
    if ([name isEqualToString:@"FBOLayerGroup"]) {
      QCPatch *riiPatch = GRPCallOriginal(@"QCRenderInImage");
      riiPatch.userInfo[@"fb_isLayerGroup"] = @YES;
      return (id)riiPatch;
    }
    
    return GRPCallOriginal(name);
  });
  
  GRPHookMethod(NSClassFromString(@"GFNode"), @selector(attributes), ^(GFNode *self) {
    NSMutableDictionary *attributes = GRPCallOriginal(self);
    return self.userInfo[@"fb_isLayerGroup"] ? [[FBOrigamiAdditions sharedAdditions] layerGroupAttributesWithAttributes:attributes] : attributes;
  });
  
  GRPHookMethod(NSClassFromString(@"GFNode"), @selector(xmlAttributes), ^(GFNode *self) {
    NSMutableDictionary *attributes = GRPCallOriginal(self);
    return self.userInfo[@"fb_isLayerGroup"] ? [[FBOrigamiAdditions sharedAdditions] layerGroupXMLAttributesWithAttributes:attributes] : attributes;
  });
}

- (NSMutableDictionary *)layerGroupAttributesWithAttributes:(NSDictionary *)attributes {
  if (!kOrigamiLayerGroupAttributes) {
    kOrigamiLayerGroupAttributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
    kOrigamiLayerGroupAttributes[@"name"] = @"Layer Group";
  }
  
  return kOrigamiLayerGroupAttributes;
}

- (NSMutableDictionary *)layerGroupXMLAttributesWithAttributes:(NSDictionary *)attributes {
  if (!kOrigamiLayerGroupXMLAttributes) {
    NSString *patchName = @"Layer Group";
    
    kOrigamiLayerGroupXMLAttributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
    kOrigamiLayerGroupXMLAttributes[@"name"] = patchName;
    
    NSMutableDictionary *newNodeAttributes = [NSMutableDictionary dictionaryWithDictionary:attributes[@"nodeAttributes"]];
    newNodeAttributes[@"name"] = patchName;
    kOrigamiLayerGroupXMLAttributes[@"nodeAttributes"] = newNodeAttributes;
  }
  
  return kOrigamiLayerGroupXMLAttributes;
}

#pragma mark Convert to Layer Group Menu Item

- (void)addConvertToLayerGroupMenuItem {
  GRPHookMethod([QCPatchActor class], @selector(menuForNode:view:), ^(QCPatchActor *self, QCPatch *node, id view) {
    NSMenu *menu = GRPCallOriginal(node,view);
    
    if ([node isMemberOfClass:NSClassFromString(@"QCRenderInImage")] && !node.userInfo[@"fb_isLayerGroup"]) {
      [menu addItem:[NSMenuItem separatorItem]];

      NSMenuItem *item = [menu addItemWithTitle:@"Convert to Layer Group" keyEquivalent:@"" target:[FBOrigamiAdditions sharedAdditions] action:@selector(convertToLayerGroup:) state:NO];
      item.representedObject = node;
    }
    
    return menu;
  });
}

- (void)convertToLayerGroup:(NSMenuItem *)item {
  QCPatch *node = (QCPatch *)item.representedObject;
  node.userInfo[@"fb_isLayerGroup"] = @YES;
  
  [self.patchView setNeedsDisplay:YES];
}

#pragma mark Interaction Patch Support

- (BOOL)execute:(QCOpenGLContext*)context time:(double)time arguments:(NSDictionary*)args {
  BOOL flag = [self original_execute:context time:time arguments:args];
  
  QCImagePort *imagePort = [(QCRenderInImage *)self portForKey:@"outputImage"];
  
  if (imagePort != nil) {
    QCImage *imageValue = imagePort.imageValue;
    [imageValue setMetadata:self forKey:@"FBAttachedRII" shouldForward:NO];
  }
  
  return flag;
}

@end