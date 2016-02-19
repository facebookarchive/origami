/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiAdditions+PatchMenu.h"
#import "NSObject+AssociatedObjects.h"
#import "QCPatch+FBAdditions.h"

#define fequal(a,b) (fabs((a) - (b)) < FLT_EPSILON)
#define fequalzero(a) (fabs(a) < FLT_EPSILON)

@implementation FBOrigamiAdditions (PatchMenu)

- (void)setupPatchMenu {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectionDidChange:) name:@"GFGraphEditorViewSelectionDidChangeNotification" object:nil];
  
  [self addPatchMenu];
}

- (void)addPatchMenu {
  self.patchMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@"Patch"];
  self.patchMenu.autoenablesItems = NO;
  NSMenuItem *patchMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"" action:NULL keyEquivalent:@""];
  [patchMenuItem setSubmenu:self.patchMenu];
  [[[NSApplication sharedApplication] mainMenu] insertItem:patchMenuItem atIndex:4];
  
  NSMenuItem *toggleEnabled = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Enable / Disable" action:@selector(toggleEnabled:) keyEquivalent:@"e"];
  [toggleEnabled setKeyEquivalentModifierMask:NSAlternateKeyMask|NSShiftKeyMask];
  toggleEnabled.target = self;
  toggleEnabled.enabled = NO;
  [self.patchMenu addItem:toggleEnabled];
  
  [self.patchMenu addItem:[NSMenuItem separatorItem]];
  
  NSMenuItem *bringForward = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Bring Forward" action:@selector(bringForward:) keyEquivalent:@"]"];
  [bringForward setKeyEquivalentModifierMask:NSCommandKeyMask];
  bringForward.target = self;
  bringForward.enabled = NO;
  [self.patchMenu addItem:bringForward];
  
  NSMenuItem *bringToFront = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Bring to Front" action:@selector(bringToFront:) keyEquivalent:@"]"];
  [bringToFront setKeyEquivalentModifierMask:NSCommandKeyMask|NSShiftKeyMask];
  bringToFront.target = self;
  bringToFront.enabled = NO;
  [self.patchMenu addItem:bringToFront];
  
  NSMenuItem *sendBackward = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Send Backward" action:@selector(sendBackward:) keyEquivalent:@"["];
  [sendBackward setKeyEquivalentModifierMask:NSCommandKeyMask];
  sendBackward.target = self;
  sendBackward.enabled = NO;
  [self.patchMenu addItem:sendBackward];
  
  NSMenuItem *sendToBack = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Send to Back" action:@selector(sendToBack:) keyEquivalent:@"["];
  [sendToBack setKeyEquivalentModifierMask:NSCommandKeyMask|NSShiftKeyMask];
  sendToBack.target = self;
  sendToBack.enabled = NO;
  [self.patchMenu addItem:sendToBack];
  
  [self.patchMenu addItem:[NSMenuItem separatorItem]];
  
  NSMenuItem *addPort = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Add Port" action:@selector(addPort:) keyEquivalent:@"]"];
  [addPort setKeyEquivalentModifierMask:NSCommandKeyMask];
  addPort.target = self;
  addPort.enabled = NO;
  [self.patchMenu addItem:addPort];
  
  NSMenuItem *removePort = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Remove Port" action:@selector(removePort:) keyEquivalent:@"["];
  [removePort setKeyEquivalentModifierMask:NSCommandKeyMask];
  removePort.target = self;
  removePort.enabled = NO;
  [self.patchMenu addItem:removePort];
  
  [self.patchMenu addItem:[NSMenuItem separatorItem]];
  
  // Input Type
  
  NSMenuItem *inputType = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Input Type" action:NULL keyEquivalent:@""];
  inputType.enabled = NO;
  self.inputTypeMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""];
  [self.patchMenu addItem:inputType];
  [self.patchMenu setSubmenu:self.inputTypeMenu forItem:inputType];
  
  NSArray *typeNames = [NSArray arrayWithObjects:@"Virtual",@"-",@"Boolean",@"Index",@"Number",@"Color",@"String", nil];
  
  for (NSString *title in typeNames) {
    NSMenuItem *item;
    if ([title isEqualToString:@"-"]) {
      item = [NSMenuItem separatorItem];
    } else {
      item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:title action:@selector(changeType:) keyEquivalent:[title substringToIndex:1]];
      [item setKeyEquivalentModifierMask:NSAlternateKeyMask|NSShiftKeyMask];
      item.target = self;
    }
    [self.inputTypeMenu addItem:item];
    
    Class portClass = NSClassFromString([NSString stringWithFormat:@"QC%@Port",title]);
    [item associateValue:portClass withKey:@"fb_portClass"];
  }
  
  // Logic Operations
  
  NSMenuItem *logicOperation = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Logic Operation" action:NULL keyEquivalent:@""];
  logicOperation.enabled = NO;
  self.logicOperationMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""];
  [self.patchMenu addItem:logicOperation];
  [self.patchMenu setSubmenu:self.logicOperationMenu forItem:logicOperation];
  
  NSArray *logicNames = [NSArray arrayWithObjects:@"AND",@"OR",@"XOR",@"NOT",nil];
  NSUInteger count = 0;
  
  for (NSString *title in logicNames) {
    NSMenuItem *item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:title action:@selector(changeLogicType:) keyEquivalent:[title substringToIndex:1]];
    [item setKeyEquivalentModifierMask:NSAlternateKeyMask|NSShiftKeyMask];
    item.target = self;
    item.tag = count;
    [self.logicOperationMenu addItem:item];
    count++;
  }
  
  // Math Operations
  
  NSMenuItem *mathOperation = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Math Operation" action:NULL keyEquivalent:@""];
  mathOperation.enabled = NO;
  NSMenu *mathOperationMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""];
  [self.patchMenu addItem:mathOperation];
  [self.patchMenu setSubmenu:mathOperationMenu forItem:mathOperation];
  
  NSArray *types = @[   @[@"+", @"p", @(NSAlternateKeyMask|NSShiftKeyMask)],
                        @[@"-", @"-", @(NSAlternateKeyMask|NSShiftKeyMask)],
                        @[@"x", @"*", @(NSAlternateKeyMask)],
                        @[@"/", @"/", @(NSAlternateKeyMask|NSShiftKeyMask)],
                        @[@"%", @"%", @(NSAlternateKeyMask)]   ];
  
  for (int i = 0; i < types.count; i++) {
    NSString *title = types[i][0];
    NSString *keyEquivalent = types[i][1];
    NSInteger *modifier = [types[i][2] integerValue];
    
    NSMenuItem *item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:title action:@selector(changeMathOperation:) keyEquivalent:keyEquivalent];
    [item setKeyEquivalentModifierMask:modifier];
    item.target = self;
    item.tag = i;
    [mathOperationMenu addItem:item];
  }
  
  // Patch Alignment
  
  [self.patchMenu addItem:[NSMenuItem separatorItem]];
  
  unichar leftKey = NSLeftArrowFunctionKey;
  NSMenuItem *leftAlign = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Left Align" action:@selector(horizontalAlign:) keyEquivalent:[NSString stringWithCharacters:&leftKey length:1]];
  leftAlign.keyEquivalentModifierMask = NSCommandKeyMask;
  leftAlign.target = self;
  leftAlign.enabled = NO;
  leftAlign.tag = 0;
  [self.patchMenu addItem:leftAlign];
  
  unichar rightKey = NSRightArrowFunctionKey;
  NSMenuItem *rightAlign = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Right Align" action:@selector(horizontalAlign:) keyEquivalent:[NSString stringWithCharacters:&rightKey length:1]];
  rightAlign.keyEquivalentModifierMask = NSCommandKeyMask;
  rightAlign.target = self;
  rightAlign.enabled = NO;
  rightAlign.tag = 1;
  [self.patchMenu addItem:rightAlign];
}

#pragma mark Patch Menu Items

- (void)changeType:(NSMenuItem *)menuItem {
  for (QCPatch *aPatch in [self selectedPatches]) {
    if ([aPatch respondsToSelector:@selector(setPortClass:)]) {
      Class portClass = [menuItem associatedValueForKey:@"fb_portClass"];
      
      if ([aPatch isMemberOfClass:NSClassFromString(@"FBWirelessInPatch")])
        [aPatch performSelector:@selector(setPortClass:) withObject:portClass];
      else
        [aPatch setValue:portClass forStateKey:@"portClass"];
    }
  }
}

- (void)changeLogicType:(NSMenuItem *)menuItem {
  for (QCPatch *aPatch in [self selectedPatches]) {
    if ([aPatch isMemberOfClass:NSClassFromString(@"QCLogic")]) {
      [aPatch __setValue:[NSNumber numberWithInt:menuItem.tag] forPortKey:@"inputOperation"];
    }
  }
}

- (void)changeMathOperation:(NSMenuItem *)menuItem {
  for (QCPatch *aPatch in [self selectedPatches]) {
    if ([aPatch isMemberOfClass:NSClassFromString(@"QCMath")]) {
      for (QCPort *port in [aPatch inputPorts]) {
        if ([port isMemberOfClass:[QCIndexPort class]]) {
          [aPatch __setValue:[NSNumber numberWithInt:menuItem.tag] forPortKey:port.key];
        }
      }
    }
  }
}

- (void)toggleEnabled:(id)sender {
  for (QCPatch *aPatch in [self selectedPatches]) {
    QCBooleanPort *port = [aPatch _enableInput];
    [aPatch __setValue:[NSNumber numberWithBool:!port.booleanValue] forPortKey:port.key];
  }
}

- (void)bringForward:(id)sender {
  [self moveSelectedPatchesInForwardDirection:YES allTheWay:NO];
}

- (void)bringToFront:(id)sender {
  [self moveSelectedPatchesInForwardDirection:YES allTheWay:YES];
}

- (void)sendBackward:(id)sender {
  [self moveSelectedPatchesInForwardDirection:NO allTheWay:NO];
}

- (void)sendToBack:(id)sender {
  [self moveSelectedPatchesInForwardDirection:NO allTheWay:YES];
}

- (void)moveSelectedPatchesInForwardDirection:(BOOL)forward allTheWay:(BOOL)allTheWay {
  // Only works predictably with 1 consumer selected
  
  for (QCPatch *selectedPatch in [self selectedPatches]) {
    if (selectedPatch._executionMode == kQCPatchExecutionModeConsumer) {
      QCPatch *currentPatch = [self currentPatch];
      NSUInteger newOrder = 0;
      
      if (allTheWay) {
        NSUInteger maxIndex = [currentPatch consumerSubpatches].count - 1;
        newOrder = forward ? maxIndex : 0;
      } else {
        NSUInteger currentIndex = [currentPatch orderForConsumerSubpatch:selectedPatch];
        newOrder = forward ? currentIndex+1 : currentIndex-1;
      }
      
      @try {
        [currentPatch setOrder:newOrder forConsumerSubpatch:selectedPatch];
      } @catch (NSException *exception) {}
    }
  }
}

- (void)addPort:(id)sender {
  [self changePortCountInPositiveDirection:YES];
}

- (void)removePort:(id)sender {
  [self changePortCountInPositiveDirection:NO];
}

- (void)changePortCountInPositiveDirection:(BOOL)positive {
  NSInteger delta = positive ? 1 : -1;
  
  for (QCPatch *selectedPatch in [self selectedPatches]) {
    if ([selectedPatch respondsToSelector:@selector(setInputCount:)]) {
      QCMultiplexer *multiplexer = (QCMultiplexer *)selectedPatch;
      [multiplexer setInteger:[multiplexer inputCount] + delta forStateKey:@"inputCount"];
    }
    else if ([selectedPatch respondsToSelector:@selector(setOutputCount:)]) {
      QCDemultiplexer *demultiplexer = (QCDemultiplexer *)selectedPatch;
      [demultiplexer setInteger:[demultiplexer outputCount] + delta forStateKey:@"outputCount"];
    }
    else if ([selectedPatch isMemberOfClass:NSClassFromString(@"QCMath")]) {
      QCMath *math = (QCMath *)selectedPatch;
      [math setInteger:[math numberOfOperations] + delta forStateKey:@"numberOfOperations"];
    }
  }
}

- (void)horizontalAlign:(NSMenuItem *)menuItem {
  CGFloat extent = 0;
  
  for (QCPatch *patch in [self selectedPatches]) {
    if (!menuItem.tag) {
      CGFloat patchExtent = patch.fb_actorPosition.x;
      if (patchExtent > extent || fequalzero(extent)) {
        extent = patchExtent;
      }
    } else {
      CGFloat patchExtent = patch.fb_actorPosition.x + patch.fb_actorSize.width;
      if (patchExtent < extent || fequalzero(extent)) {
        extent = patchExtent;
      }
    }
  }
  
  for (QCPatch *patch in [self selectedPatches]) {
    NSPoint delta = NSZeroPoint;
    delta.x = !menuItem.tag ? extent - patch.fb_actorPosition.x : extent - (patch.fb_actorPosition.x + patch.fb_actorSize.width);
    [[self patchView] __undoableMove:patch context:&delta];
  }
}

- (void)selectionDidChange:(NSNotification *)notif {
  QCPatchEditorView *editorView = notif.object;
  
  if (![editorView isMemberOfClass:[QCPatchEditorView class]]) {
    return;
  }
  
  NSArray *selectedNodes = [[editorView patch] selectedNodes];
  
  if (selectedNodes == nil || selectedNodes.count < 1) {
    return;
  }
  
  BOOL consumerPatchIsSelected = NO;
  BOOL logicPatchIsSelected = NO;
  BOOL inputPatchIsSelected = NO;
  BOOL mathPatchIsSelected = NO;
  BOOL variablePortPatchIsSelected = NO;
  
  for (QCPatch *patch in selectedNodes) {
    if (patch._executionMode == kQCPatchExecutionModeConsumer) {
      consumerPatchIsSelected = YES;
    }
    else if ([patch isMemberOfClass:NSClassFromString(@"QCLogic")]) {
      logicPatchIsSelected = YES;
    }
    else if ([patch isMemberOfClass:NSClassFromString(@"QCMath")]) {
      mathPatchIsSelected = YES;
    }
    else if ([patch isMemberOfClass:NSClassFromString(@"QCPlugInPatch")]) {
      if ([[(QCPlugInPatch *)patch plugIn] isMemberOfClass:NSClassFromString(@"_1024_SelectorPlugIn")]) {
        variablePortPatchIsSelected = YES;
      }
    }
    else if ([patch respondsToSelector:@selector(setInputCount:)] || [patch respondsToSelector:@selector(setOutputCount:)]) {
      variablePortPatchIsSelected = YES;
    }
    
    if ([patch respondsToSelector:@selector(setPortClass:)]) {
      inputPatchIsSelected = YES;
    }
  }
  
  [self.patchMenu itemWithTitle:@"Enable / Disable"].enabled = consumerPatchIsSelected;
  [self.patchMenu itemWithTitle:@"Bring Forward"].enabled = consumerPatchIsSelected;
  [self.patchMenu itemWithTitle:@"Bring to Front"].enabled = consumerPatchIsSelected;
  [self.patchMenu itemWithTitle:@"Send Backward"].enabled = consumerPatchIsSelected;
  [self.patchMenu itemWithTitle:@"Send to Back"].enabled = consumerPatchIsSelected;
  [self.patchMenu itemWithTitle:@"Input Type"].enabled = inputPatchIsSelected;
  [self.patchMenu itemWithTitle:@"Logic Operation"].enabled = logicPatchIsSelected;
  [self.patchMenu itemWithTitle:@"Math Operation"].enabled = mathPatchIsSelected;
  [self.patchMenu itemWithTitle:@"Add Port"].enabled = variablePortPatchIsSelected || mathPatchIsSelected;
  [self.patchMenu itemWithTitle:@"Remove Port"].enabled = variablePortPatchIsSelected || mathPatchIsSelected;
  
  [self.patchMenu itemWithTitle:@"Left Align"].enabled = (selectedNodes.count > 1);
  [self.patchMenu itemWithTitle:@"Right Align"].enabled = (selectedNodes.count > 1);
  
  // Handle keyboard shortcut conflicts
  [self.inputTypeMenu itemWithTitle:@"Number"].keyEquivalentModifierMask = inputPatchIsSelected ? NSAlternateKeyMask|NSShiftKeyMask : 0;
  [self.logicOperationMenu itemWithTitle:@"NOT"].keyEquivalentModifierMask = logicPatchIsSelected ? NSAlternateKeyMask|NSShiftKeyMask : 0;
  [self.patchMenu itemWithTitle:@"Add Port"].keyEquivalentModifierMask = variablePortPatchIsSelected || mathPatchIsSelected ? NSCommandKeyMask : 0;
  [self.patchMenu itemWithTitle:@"Remove Port"].keyEquivalentModifierMask = variablePortPatchIsSelected || mathPatchIsSelected ? NSCommandKeyMask : 0;
  [self.patchMenu itemWithTitle:@"Bring Forward"].keyEquivalentModifierMask = consumerPatchIsSelected ? NSCommandKeyMask : 0;
  [self.patchMenu itemWithTitle:@"Send Backward"].keyEquivalentModifierMask = consumerPatchIsSelected ? NSCommandKeyMask : 0;
}

@end
