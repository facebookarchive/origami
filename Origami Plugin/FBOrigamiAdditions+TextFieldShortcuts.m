/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiAdditions+TextFieldShortcuts.h"
#import "NSObject+FBAdditions.h"

@interface FBOrigamiAdditions () <NSTextFieldDelegate>
- (void)original__layoutUpdated:(id)fp8;
@end

@implementation FBOrigamiAdditions (TextFieldShortcuts)

- (void)setupTextFieldShortcuts {
  [self fb_swizzleInstanceMethod:@selector(_layoutUpdated:) forClassName:@"QCPatchParametersView"];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command {
  if (![control isKindOfClass:[NSTextField class]])
    return NO;
  NSTextField *field = (NSTextField *)control;
  
  if (command == @selector(moveUp:)) { // Up
    [field setDoubleValue:field.doubleValue + 1.0];
    [field textShouldEndEditing:textView];
    return YES;
  } else if (command == @selector(moveDown:)) { // Down
    [field setDoubleValue:field.doubleValue - 1.0];
    [field textShouldEndEditing:textView];
    return YES;
  } else if (command == @selector(moveUpAndModifySelection:)) { // Shift+Up
    [field setDoubleValue:field.doubleValue + 10.0];
    [field textShouldEndEditing:textView];
    return YES;
  } else if (command == @selector(moveDownAndModifySelection:)) { // Shift+Down
    [field setDoubleValue:field.doubleValue - 10.0];
    [field textShouldEndEditing:textView];
    return YES;
  } else if (command == @selector(moveParagraphBackwardAndModifySelection:)) { // Opt+Shift+Up
    [field setDoubleValue:field.doubleValue + 0.1];
    [field textShouldEndEditing:textView];
    return YES;
  } else if (command == @selector(moveParagraphForwardAndModifySelection:)) { // Opt+Shift+Down
    [field setDoubleValue:field.doubleValue - 0.1];
    [field textShouldEndEditing:textView];
    return YES;
  }
  
  return NO;
}

- (void)_layoutUpdated:(id)fp8 {
  for (NSView *view in [self valueForKey:@"views"]) {
    if ([view isKindOfClass:[NSView class]]) {
      for (NSView *subview in view.subviews) {
        if ([subview isMemberOfClass:[NSTextField class]]) {
          NSTextField *field = (NSTextField *)subview;
          if (field.delegate == nil)
            field.delegate = [FBOrigamiAdditions sharedAdditions];
        }
      }
    }
  }
  
  [self original__layoutUpdated:fp8];
}

@end
