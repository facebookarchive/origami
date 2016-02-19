/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiAdditions+DragAndDrop.h"
#import "FBOrigamiAdditions+FileCreation.h"
#import "FBOrigamiAdditions+StructureIterator.h"
#import "NSObject+FBAdditions.h"
#import "QCPort+FBAdditions.h"
#import "QCPatchView+FBAdditions.h"
#import "FBOLiveFilePatch.h"

@interface FBOrigamiAdditions ()
- (BOOL)original__addNode:(id)fp8 atPosition:(NSPoint)fp12;
@end

@implementation FBOrigamiAdditions (DragAndDrop)

- (void)setupDragAndDrop {
  [self fb_swizzleInstanceMethod:@selector(_addNode:atPosition:) forClassName:@"QCPatchView"];
}

- (BOOL)_addNode:(QCPatch *)patch atPosition:(NSPoint)position {
  QCPatch *hoveredPatch = [[FBOrigamiAdditions sharedAdditions] patchUnderCursorInPatchView:(QCPatchView *)self];
  
  BOOL flag = [self original__addNode:patch atPosition:position];
  
  if ([patch isMemberOfClass:NSClassFromString(@"QCImageLoader")]) {
    QCPatchView *patchView = (QCPatchView *)self;
    QCImageLoader *imageLoader = (QCImageLoader *)patch;
    QCPatch *imagePatch = imageLoader;
    
    BOOL optionKeyIsDown = ([NSEvent modifierFlags] & NSAlternateKeyMask) > 0;
    BOOL commandKeyIsDown = ([NSEvent modifierFlags] & NSCommandKeyMask) > 0;

    if (optionKeyIsDown && !commandKeyIsDown) {
      return flag;
    }
    
    // Replace the image patch with a Live Image patch if the option and command keys are held down
    if (optionKeyIsDown && commandKeyIsDown) {
      FBOLiveFilePatch *liveFilePatch = (FBOLiveFilePatch *)[QCPatch createPatchWithName:@"FBOLiveFilePatch"];
      
      // Pull the path out of the image loader and set it on the Live Image patch
      if ([imageLoader respondsToSelector:@selector(sourcePath)]) {
        NSString *path = [imageLoader performSelector:@selector(sourcePath)];
        [liveFilePatch setPathString:path];
      }
      
      [[FBOrigamiAdditions sharedAdditions] insertPatch:liveFilePatch inPatchView:patchView];
      liveFilePatch.userInfo[@"position"] = imageLoader.userInfo[@"position"];
      
      [imageLoader.parentPatch removeSubpatch:imageLoader];
      
      imagePatch = liveFilePatch;
    }
    
    // Replace the hovered image patch with the new image you're dragging in
    if ([hoveredPatch isMemberOfClass:NSClassFromString(@"QCImageLoader")]) {
      [[FBOrigamiAdditions sharedAdditions] transferValueOrConnectionsFromPort:hoveredPatch.outputPorts[0] toPort:imagePatch.outputPorts[0]];
      
      QCPort *outputPort = imagePatch.outputPorts[0];
      if (outputPort.fb_connectedPorts.count == 1)
        imagePatch.userInfo[@"position"] = [(QCPatchView *)self fb_positionValueForPatchWithPort:outputPort alignedToPort:outputPort.fb_connectedPorts[0]];
      
      [hoveredPatch.parentPatch removeSubpatch:hoveredPatch];
    }
    // Create a new layer patch and connect it to the new image patch
    else {
      NSString *spriteName = @"/layer";
      QCPatch *sprite = [QCPatch createPatchWithName:spriteName];
      
      [patchView fb_addPatch:sprite];
      
      QCPort *outputPort = imagePatch.outputPorts[0];
      QCPort *inputPort = [sprite portForKey:@"Image"];
      
      sprite.userInfo[@"position"] = [(QCPatchView *)self fb_positionValueForPatchWithPort:inputPort alignedToPort:outputPort];
      
      [[patchView graph] createConnectionFromPort:outputPort toPort:inputPort];
    }
    
    [patchView fb_setSelected:NO forPatch:imagePatch];
  }
  
  // Auto-expand Structure Iterator
  [[FBOrigamiAdditions sharedAdditions] autoExpandPatchIfStructureIterator:patch];
  
  return flag;
}

@end
