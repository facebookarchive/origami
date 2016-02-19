/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiAdditions+StructureIterator.h"
#import "NSObject+FBAdditions.h"
#import "QCPatch+FBAdditions.h"
#import "QCPort+FBAdditions.h"

@interface FBOrigamiAdditions ()
- (void)original__editNode:(QCPatch *)node;
- (void)original__editParentGraph:(id)sender;
- (void)original__publish:(id)sender;
@end

@implementation FBOrigamiAdditions (StructureIterator)

- (void)setupStructureIteratorShortcuts {
  [self fb_swizzleInstanceMethod:@selector(_editNode:) forClassName:@"GFGraphView"];
  [self fb_swizzleInstanceMethod:@selector(_editParentGraph:) forClassName:@"GFGraphView"];
  [self fb_swizzleInstanceMethod:@selector(_publish:) forClassName:@"GFNodeActor"];
}

- (void)autoExpandPatchIfStructureIterator:(QCPatch *)patch {
  NSString *structureIteratorPatch = @"/structure iterator";
  if ([[patch userInfo][@".className"] isEqualToString:structureIteratorPatch]) {
    NSString *path = [QCPatch patchAttributesWithName:structureIteratorPatch][@"path"];
    QCPatch *editablePatch = [QCPatch instantiateWithFile:path];
    editablePatch.userInfo[@"fb_className"] = structureIteratorPatch;
    [[[FBOrigamiAdditions sharedAdditions] editorController] performSelector:@selector(replacePatch:withPatch:) withObject:patch withObject:editablePatch];
  }
}

- (void)_editNode:(QCPatch *)node {
  BOOL isStructureIterator = [[node userInfo][@"fb_className"] isEqualToString:@"/structure iterator"];
  BOOL optionKeyIsPressed = ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0;
  
  if (isStructureIterator && !optionKeyIsPressed) {
    for (QCPatch *subpatch in [node subpatches]) {
      if ([subpatch isKindOfClass:NSClassFromString(@"QCIterator")]) {
        // Dive into the iterator automatically
        node = subpatch;
        break;
      }
    }
  }
  
  [self original__editNode:node];
}

- (void)_editParentGraph:(id)sender {
  [self original__editParentGraph:sender];
  
  BOOL optionKeyIsPressed = ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0;
  if (optionKeyIsPressed) {
    return;
  }
  
  QCPatch *parent = ((GFGraphView *)self).graph;
  BOOL isStructureIterator = [[parent userInfo][@"fb_className"] isEqualToString:@"/structure iterator"];
  if (isStructureIterator) { // Go up a second level automatically
    [self original__editParentGraph:sender];
  }
}

- (void)_publish:(id)sender {
  NSDictionary *publishedPortRepresentation = [sender representedObject];
  QCPatch *graph = publishedPortRepresentation[@"graph"];
  QCPatch *parentOfParent = graph.graph;
  
  [self original__publish:sender];
  
  NSString *structureIteratorPatch = @"/structure iterator";
  if (!(parentOfParent && [[parentOfParent userInfo][@"fb_className"] isEqualToString:structureIteratorPatch])) {
    return;
  }
  
  // For Structure Iterators, publish the newly published port up a second level
  QCPort *port = publishedPortRepresentation[@"port"];
  NSArray *proxyPorts = port.fb_isInputPort ? graph.proxyInputPorts : graph.proxyOutputPorts;
  QCPort *newlyPublishedPort = proxyPorts.lastObject;
  
  QCPatchView *view = publishedPortRepresentation[@"view"];
  NSDictionary *portToPublish = @{@"graph": parentOfParent,
                                  @"port": newlyPublishedPort,
                                  @"view": view};
  [sender setRepresentedObject:portToPublish];
  
  graph.userInfo[@".protectedFromPortRename"] = @(YES);
  [self original__publish:sender];
  [graph.userInfo removeObjectForKey:@".protectedFromPortRename"];
}

@end
