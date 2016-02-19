/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiAdditions.h"

@interface FBOrigamiAdditions (KeyboardShortcuts)

- (void)setupKeyboardShortcuts;

- (void)editNameOfSelectedPatchInPatchView:(QCPatchView *)patchView;
- (void)insertLogicInPatchView:(QCPatchView *)patchView type:(FBLogicOperation)operationIndex;
- (void)insertMathInPatchView:(QCPatchView *)patchView type:(FBMathOperation)operationIndex;

@end
