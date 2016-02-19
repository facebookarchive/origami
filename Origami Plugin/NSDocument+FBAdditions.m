/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "NSDocument+FBAdditions.h"
#import "QCPatch+FBAdditions.h"
#import "NSDocument+FBAdditions.h"

@implementation NSDocument (FBAdditions)

- (GFGraphEditorView *)fb_editorView {
  GFGraphEditorView *editorView = nil;
  
  if ([self respondsToSelector:@selector(editorController)]) {
    id editorController = [self performSelector:@selector(editorController)];
    
    if ([editorController respondsToSelector:@selector(editingView)]) {
      editorView = [editorController performSelector:@selector(editingView)];
    }
  }

  return editorView;
}

- (QCPatchView *)fb_patchView {
  return self.fb_editorView.graphView;
}

- (QCPatch *)fb_graph {
  return self.fb_editorView.graph;
}

@end
