/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiAdditions+Mavericks.h"
#import "GRPHookMethod.h"

@implementation FBOrigamiAdditions (Mavericks)

// Horrible hacks to work around crashers introduced in 10.9 that we can hopefully remove if / when these bugs are fixed in the OS.

- (void)mavericksSwizzles {
  // A few methods in QC use enqueueNotification:postingStyle: to post a GFGraphEditorViewCenterDidChangeNotification when idle. This is enqueued when the document is scrolled via the mouse, keyboard, etc. When this notification is released, it releases its .object which can be a QCPatchEditorView zombie. This causes QC to crash when you scroll a document and close it. To work around this, we capture the last deallocated editor view and stop notifications from deallocating them by nil'ng out references to the zombies.
  
  __block QCPatchEditorView *lastDeallocatedEditorView = nil;
  
  GRPHookMethod(NSClassFromString(@"QCPatchEditorView"), @selector(dealloc), ^(QCPatchEditorView *self) {
    lastDeallocatedEditorView = self;
    GRPCallOriginal();
  });
  
  GRPHookMethod(NSClassFromString(@"NSConcreteNotification"), @selector(dealloc), ^(NSNotification *self) {
    if (self.object == lastDeallocatedEditorView)
      object_setInstanceVariable(self, "object", nil);
    
    GRPCallOriginal();
  });
}

@end
