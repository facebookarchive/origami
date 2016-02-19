/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <SkankySDK/SkankySDK.h>
#import <Sparkle/Sparkle.h>

typedef enum {
  FBLogicOperationAND,
  FBLogicOperationOR,
  FBLogicOperationXOR,
  FBLogicOperationNOT
} FBLogicOperation;

typedef enum {
  FBMathOperationAdd,
  FBMathOperationSubtract,
  FBMathOperationMultiply,
  FBMathOperationDivide,
  FBMathOperationModulus
} FBMathOperation;

static inline BOOL FBToolsIsInstalled() {
  return (NSClassFromString(@"FBToolsPrincipal") != nil);
}

@interface FBOrigamiAdditions : NSObject

@property void *localizePointer; // This points to the _LocalizePortInfo() function
@property (assign, nonatomic) QCPort *hoveredPort;
@property (assign, nonatomic) QCPatch *hoveredPatch;
@property (strong, nonatomic) NSMenu *origamiMenu;
@property (assign, nonatomic) BOOL linearPortConnections;

@property (strong) NSMenuItem *retinaSupportMenuItem;
@property (strong) NSMenuItem *linearPortConnectionsMenuItem;

@property (strong, nonatomic) NSMenu *patchMenu;
@property (strong, nonatomic) NSMenu *logicOperationMenu;
@property (strong, nonatomic) NSMenu *inputTypeMenu;

@property BOOL inlineValuesDisabled;
@property (strong) NSMenuItem *inlineValuesMenuItem;
@property BOOL textBackgroundsDisabled;
@property (strong) NSMenuItem *textBackgroundsMenuItem;
@property BOOL checkboxesDisabled;
@property (strong) NSMenuItem *checkboxesMenuItem;
@property BOOL customColorDisabled;
@property (strong) NSMenuItem *customColorMenuItem;
@property BOOL coreTextDisabled;
@property (strong) NSMenuItem *coreTextMenuItem;

@property BOOL tooltipsHidden;
@property (strong) NSMenuItem *hideTooltipsMenuItem;

@property (nonatomic, assign) QCPatch *patchBeingEdited;

+ (FBOrigamiAdditions *)sharedAdditions;
+ (NSBundle *)origamiBundle;
- (void)initialSetup;
- (NSString *)qcVersionNumber;

- (QCPatch *)patchUnderCursorInPatchView:(QCPatchView *)patchView;
- (QCPort *)portUnderCursorInPatchView:(QCPatchView *)patchView;
- (void)transferValueOrConnectionsFromPort:(QCPort *)oldPort toPort:(QCPort *)newPort;
- (void)insertPatch:(QCPatch *)newPatch inPatchView:(QCPatchView *)patchView;
- (void)insertPatch:(QCPatch *)newPatch inPatchView:(QCPatchView *)patchView inputPortKey:(NSString *)inputPortKey outputPortKey:(NSString *)outputPortKey;

- (QCPatchView *)patchView;
- (id)editorController;
- (id)viewerController;
- (QCPatch *)currentPatch;
- (NSArray *)selectedPatches;

@end
