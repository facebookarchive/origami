/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiAdditions+KeyboardShortcuts.h"
#import "QCPort+FBAdditions.h"
#import "QCPatchView+FBAdditions.h"
#import "QCPatch+FBAdditions.h"
#import "NSObject+FBAdditions.h"

static CGFloat kInteractionPatchPadding = 300.0;

@interface FBOrigamiAdditions ()
- (void)original_keyDown:(NSEvent *)theEvent;
@end

@implementation FBOrigamiAdditions (KeyboardShortcutsLegacy)

- (void)setupKeyboardShortcuts {
  [self fb_swizzleInstanceMethod:@selector(keyDown:) forClassName:@"GFGraphView"];
}

- (void)keyDown:(NSEvent *)theEvent {
  NSString *characters = theEvent.charactersIgnoringModifiers;
  BOOL commandKeyPressed = ([theEvent modifierFlags] & NSCommandKeyMask);
  
  BOOL keyIsNumber = NO;
  int numericKey = 0;
  
  for (int i = 0; i < 10; i++) {
    if ([characters isEqualToString:[NSString stringWithFormat:@"%d",i]]) {
      keyIsNumber = YES;
      numericKey = i;
      break;
    }
  }
  
  if (!([characters isEqualToString:@"="] || [characters isEqualToString:@"+"] || keyIsNumber))
    [self original_keyDown:theEvent];
  
  QCPatchView *patchView = [FBOrigamiAdditions sharedAdditions].patchView;
  [FBOrigamiAdditions sharedAdditions].hoveredPort = [[FBOrigamiAdditions sharedAdditions] portUnderCursorInPatchView:patchView];
  [FBOrigamiAdditions sharedAdditions].hoveredPatch = [[FBOrigamiAdditions sharedAdditions] patchUnderCursorInPatchView:patchView];
  
  if (theEvent.keyCode == 36) { // Return key
    [[FBOrigamiAdditions sharedAdditions] editNameOfSelectedPatchInPatchView:patchView];
  }
  
  if ([[FBOrigamiAdditions sharedAdditions].hoveredPatch isKindOfClass:NSClassFromString(@"QCKeyboard")] && ![characters isEqualToString:@" "] && ![FBOrigamiAdditions sharedAdditions].hoveredPort) {
    QCKeyboard *patch = (QCKeyboard *)[FBOrigamiAdditions sharedAdditions].hoveredPatch;
    QCPort *oldPort = [patch.outputPorts objectAtIndex:0];
    NSArray *connectedPorts = [oldPort fb_connectedPorts];
    
    [patch setObservedKeys:[NSArray arrayWithObject:characters]];
    
    QCPort *newPort = [patch.outputPorts objectAtIndex:0];
    for (GFPort *chainedPort in connectedPorts) {
      [[patchView graph] createConnectionFromPort:newPort toPort:chainedPort];
    }
    return;
  }
  
  else if ([characters isEqualToString:@","] && FBToolsIsInstalled()) {
    [[FBOrigamiAdditions sharedAdditions].patchView setGraph:[FBOrigamiAdditions sharedAdditions].hoveredPatch];
  }
  
  else if ([characters isEqualToString:@"."]) {
    NSDictionary *userInfo = [FBOrigamiAdditions sharedAdditions].hoveredPatch.userInfo;
    
    QCPatch *patch = nil;
    if (userInfo[@".className"]) { // Patch is non-editable
      NSDictionary *attr = [QCPatch patchAttributesWithName:userInfo[@".className"]];
      NSString *path = attr[@"path"];
      patch = [QCPatch instantiateWithFile:path];
      patch.userInfo[@"fb_className"] = userInfo[@".className"];
    }
    else if (userInfo[@"fb_className"]) { // Patch was made editable with this keyboard shortcut
      patch = [QCPatch createPatchWithName:userInfo[@"fb_className"]];
    }
    
    if (patch) {
      if (userInfo[@"name"])
        patch.userInfo[@"name"] = userInfo[@"name"];
      
      NSUInteger order;
      BOOL isConsumerPatch = ([FBOrigamiAdditions sharedAdditions].hoveredPatch._executionMode == kQCPatchExecutionModeConsumer);
      if (isConsumerPatch)
        order = [[FBOrigamiAdditions sharedAdditions].hoveredPatch.parentPatch orderForConsumerSubpatch:[FBOrigamiAdditions sharedAdditions].hoveredPatch];
      
      [[[FBOrigamiAdditions sharedAdditions] editorController] performSelector:@selector(replacePatch:withPatch:) withObject:[FBOrigamiAdditions sharedAdditions].hoveredPatch withObject:patch];
      [patchView fb_setSelected:YES forPatch:patch];
      
      if (isConsumerPatch)
        [patch.parentPatch setOrder:order forConsumerSubpatch:patch];
    }
  }
  
  else if ([characters isEqualToString:@"g"]) {
    QCPatch *hoveredPatch = [FBOrigamiAdditions sharedAdditions].hoveredPatch;
    BOOL hoveredOverImagePatch = ([hoveredPatch isKindOfClass:NSClassFromString(@"QCImageLoader")] || [hoveredPatch isKindOfClass:NSClassFromString(@"FBOLiveFilePatch")]) && ([FBOrigamiAdditions sharedAdditions].hoveredPort == nil);
    BOOL hoveredOverRII = [hoveredPatch isKindOfClass:NSClassFromString(@"QCRenderInImage")] && ([FBOrigamiAdditions sharedAdditions].hoveredPort == nil);
    
    if (hoveredPatch && !(hoveredOverImagePatch || hoveredOverRII))
      return;
    
    QCPatch *riiPatch = [QCPatch createPatchWithName:@"QCRenderInImage"];
    riiPatch.userInfo[@"fb_isLayerGroup"] = @YES;
    [[riiPatch portForKey:@"inputWidth"] setIndexValue:750];
    [[riiPatch portForKey:@"inputHeight"] setIndexValue:1334];
    
    [[FBOrigamiAdditions sharedAdditions] insertPatch:riiPatch inPatchView:patchView];
    
    if (hoveredOverImagePatch || hoveredOverRII) {
      QCPatch *sprite = [QCPatch createPatchWithName:@"/layer"];
      [riiPatch addSubpatch:sprite];
      
      NSPoint position = [patchView _centerPoint];
      position.y -= roundf(sprite.fb_actorSizeInKeyPatchView.height / 2.0);
      sprite.userInfo[@"position"] = [NSValue valueWithPoint:position];
      
      QCImagePort *imagePort = hoveredPatch.outputPorts[0];
      
      if (hoveredOverImagePatch) {
        QCImage *image = imagePort.imageValue;
        if (!image.isInfinite) {
          [[riiPatch portForKey:@"inputWidth"] setIndexValue:image.bounds.size.width];
          [[riiPatch portForKey:@"inputHeight"] setIndexValue:image.bounds.size.height];
        }
      } else {
        [[riiPatch portForKey:@"inputWidth"] setIndexValue:[[hoveredPatch portForKey:@"inputWidth"] indexValue]];
        [[riiPatch portForKey:@"inputHeight"] setIndexValue:[[hoveredPatch portForKey:@"inputHeight"] indexValue]];
      }
      
      NSArray *connectedPorts = [imagePort fb_connectedPorts];
      
      [[hoveredPatch parentPatch] removeSubpatch:hoveredPatch];
      [riiPatch addSubpatch:hoveredPatch];
      
      hoveredPatch.userInfo[@"position"] = [patchView fb_positionValueForPatchWithPort:imagePort alignedToPort:[sprite portForKey:@"Image"]];
      
      [riiPatch createConnectionFromPort:imagePort toPort:[sprite portForKey:@"Image"]];
      
      QCPort *riiPort = [riiPatch.outputPorts objectAtIndex:0];
      for (GFPort *chainedPort in connectedPorts) {
        [[patchView graph] createConnectionFromPort:riiPort toPort:chainedPort];
      }
    }
    
    return;
  }
  
  else if ([characters isEqualToString:@"w"] || [characters isEqualToString:@"W"]) {
    QCPort *port = [FBOrigamiAdditions sharedAdditions].hoveredPort;
    QCPatch *wirelessPatch = nil;
    
    if (port) {
      if (port.fb_isInputPort) {
        wirelessPatch = [QCPatch createPatchWithName:@"FBWirelessOutPatch"];
      } else {
        wirelessPatch = [QCPatch createPatchWithName:@"FBWirelessInPatch"];
        
        if ([port baseClass])
          [(QCMultiplexer *)wirelessPatch setPortClass:[port baseClass]]; // Multiplexer cast to supress warnings
        
        if ([port.node.attributes[@"name"] isEqualToString:@"Switch"] && port.node.userInfo[@"name"])
          wirelessPatch.userInfo[@"name"] = port.node.userInfo[@"name"]; // Set the brodcaster name to the custom title of the Switch patch
        else if (port.fb_name)
          wirelessPatch.userInfo[@"name"] = port.fb_name;
      }
    }
    else {
      if ([characters isEqualToString:@"w"])
        wirelessPatch = [QCPatch createPatchWithName:@"FBWirelessInPatch"];
      else
        wirelessPatch = [QCPatch createPatchWithName:@"FBWirelessOutPatch"];
    }

    [[FBOrigamiAdditions sharedAdditions] insertPatch:wirelessPatch inPatchView:patchView];
  }
  
  if (keyIsNumber && ![FBOrigamiAdditions sharedAdditions].hoveredPort) {
    QCPort *alphaPort = [[FBOrigamiAdditions sharedAdditions].hoveredPatch portForKey:@"Alpha"];
    
    if (alphaPort && alphaPort.fb_isInputPort && alphaPort.fb_connectedPorts.count < 1) {
      CGFloat alpha = (numericKey == 0) ? 10.0 : numericKey / 10.0;
      [alphaPort setValue:[NSNumber numberWithFloat:alpha]];
      return;
    }
  }
  
  if ([FBOrigamiAdditions sharedAdditions].hoveredPatch && ![FBOrigamiAdditions sharedAdditions].hoveredPort) {
    return;
  }
  
  // Everything below only activates when your mouse isn't hovered over the body of a patch
  
  if (([characters isEqualToString:@"p"] || [characters isEqualToString:@"P"]) && [FBOrigamiAdditions sharedAdditions].hoveredPort) {
    // -[QCPatchActor _publish:] is expecting a NSMenuItem with a representedObject of a dictionary with the following structure.
    
    NSDictionary *dict = @{@"graph": [[FBOrigamiAdditions sharedAdditions].hoveredPatch parentPatch],
                           @"port": [FBOrigamiAdditions sharedAdditions].hoveredPort,
                           @"view": patchView};
    
    NSMenuItem *fakeItem = [[NSMenuItem alloc] init];
    fakeItem.representedObject = dict;
    
    GFNode *patch = [FBOrigamiAdditions sharedAdditions].hoveredPort.node;
    QCPatchActor *actor = [patchView nodeActorForNode:patch];
    
    if ([characters isEqualToString:@"p"]) {
      patch.userInfo[@".protectedFromPortRename"] = [NSNumber numberWithBool:YES]; // This supresses the port renaming text field from appearing.
      [actor _publish:fakeItem];
      [patch.userInfo removeObjectForKey:@".protectedFromPortRename"];
    } else {
      [actor _publish:fakeItem];
    }
  }
  
  else if ([characters isEqualToString:@"u"]) {
    if (FBToolsIsInstalled())
      [[FBOrigamiAdditions sharedAdditions] insertPatch:[QCPatch createPatchWithName:@"/pulse 3"] inPatchView:patchView];
    else
      [[FBOrigamiAdditions sharedAdditions] insertPatch:[QCPatch createPatchWithName:@"QCPulse"] inPatchView:patchView];
  }
  
  else if ([characters isEqualToString:@"i"]) {
    QCPatch *interactionPatch = [QCPatch createPatchWithName:@"FBOInteractionPatch"];
    [[FBOrigamiAdditions sharedAdditions] insertPatch:interactionPatch inPatchView:patchView];
    
    if ([FBOrigamiAdditions sharedAdditions].hoveredPort.baseClass == [QCInteractionPort class]) {
      NSPoint newPosition = [patchView fb_positionForPatchWithPort:interactionPatch.outputPorts[0] alignedToPort:[FBOrigamiAdditions sharedAdditions].hoveredPort];
      newPosition.x -= kInteractionPatchPadding;
      interactionPatch.userInfo[@"position"] = [NSValue valueWithPoint:newPosition];
      
      QCPatch *connectedPatch = [FBOrigamiAdditions sharedAdditions].hoveredPort.parentPatch;
      if (connectedPatch.userInfo[@"name"])
        interactionPatch.userInfo[@"name"] = connectedPatch.userInfo[@"name"];
    }
  }
  
  else if ([characters isEqualToString:@"s"]) {
    if ([FBOrigamiAdditions sharedAdditions].hoveredPort) {
      /*
       -[QCPatchActor _refactor:] is expecting a NSMenuItem with a representedObject of a dictionary with the following structure.
       */
      
      NSArray *oldGraph = [NSArray arrayWithArray:[[[FBOrigamiAdditions sharedAdditions].hoveredPatch parentPatch] subpatches]];
      
      NSDictionary *dict = @{@"graph": [[FBOrigamiAdditions sharedAdditions].hoveredPatch parentPatch],
                             @"port": [FBOrigamiAdditions sharedAdditions].hoveredPort,
                             @"view": patchView};
      
      NSMenuItem *fakeItem = [[NSMenuItem alloc] init];
      fakeItem.representedObject = dict;
      
      QCPatchActor *actor = [patchView nodeActorForNode:[FBOrigamiAdditions sharedAdditions].hoveredPort.node];
      [actor _refactor:fakeItem];
      
      // Find the splitter that was added
      NSMutableArray *newGraph = [NSMutableArray arrayWithArray:[[[FBOrigamiAdditions sharedAdditions].hoveredPatch parentPatch] subpatches]];
      [newGraph removeObjectsInArray:oldGraph];
      
      QCPatch *splitter = newGraph.firstObject;
      
      // Position the patch
      QCPort *connectedSplitterPort = [FBOrigamiAdditions sharedAdditions].hoveredPort.fb_isInputPort ? splitter.outputPorts[0] : splitter.inputPorts[0];
      splitter.userInfo[@"position"] = [patchView fb_positionValueForPatchWithPort:connectedSplitterPort alignedToPort:[FBOrigamiAdditions sharedAdditions].hoveredPort];
      
      // Fix the QC port naming bug
      NSString *portName = [FBOrigamiAdditions sharedAdditions].hoveredPort.fb_name;
      ((QCPort *)splitter.inputPorts[0]).userInfo[@"name"] = portName;
      ((QCPort *)splitter.outputPorts[0]).userInfo[@"name"] = portName;
    }
    else {
      [[FBOrigamiAdditions sharedAdditions] insertPatch:[QCPatch createPatchWithName:@"QCSplitter"] inPatchView:patchView];
    }
  }
  
  else if ([characters isEqualToString:@"S"]) {
    [[FBOrigamiAdditions sharedAdditions] insertPatch:[QCPatch createPatchWithName:@"/switch"] inPatchView:patchView];
  }
  
  else if ([characters isEqualToString:@"A"]) {
    [[FBOrigamiAdditions sharedAdditions] insertLogicInPatchView:patchView type:FBLogicOperationAND];
  }
  
  else if ([characters isEqualToString:@"O"]) {
    [[FBOrigamiAdditions sharedAdditions] insertLogicInPatchView:patchView type:FBLogicOperationOR];
  }
  
  else if ([characters isEqualToString:@"N"]) {
    [[FBOrigamiAdditions sharedAdditions] insertLogicInPatchView:patchView type:FBLogicOperationNOT];
  }
  
  else if ([characters isEqualToString:@"="] || [characters isEqualToString:@"+"]) {
    [[FBOrigamiAdditions sharedAdditions] insertMathInPatchView:patchView type:FBMathOperationAdd];
  }
  
  else if ([characters isEqualToString:@"-"]) {
    [[FBOrigamiAdditions sharedAdditions] insertMathInPatchView:patchView type:FBMathOperationSubtract];
  }
  
  else if ([characters isEqualToString:@"*"] || [characters isEqualToString:@"8"] || [characters isEqualToString:@"x"]) {
    [[FBOrigamiAdditions sharedAdditions] insertMathInPatchView:patchView type:FBMathOperationMultiply];
  }
  
  else if ([characters isEqualToString:@"/"]) {
    [[FBOrigamiAdditions sharedAdditions] insertMathInPatchView:patchView type:FBMathOperationDivide];
  }
  
  else if ([characters isEqualToString:@"%"]) {
    [[FBOrigamiAdditions sharedAdditions] insertMathInPatchView:patchView type:FBMathOperationModulus];
  }
  
  else if ([characters isEqualToString:@"c"]) {
    QCPort *hoveredPort = [FBOrigamiAdditions sharedAdditions].hoveredPort;
    
    if (!(hoveredPort && commandKeyPressed)) {
      [[FBOrigamiAdditions sharedAdditions] insertPatch:[QCPatch createPatchWithName:@"QCConditional"] inPatchView:patchView];
    } else {
      // Write to pasteboard
      id value;
      
      if ([hoveredPort isKindOfClass:[QCBooleanPort class]]) {
        value = @([(QCBooleanPort *)hoveredPort booleanValue]);
      } else if ([hoveredPort isKindOfClass:[QCColorPort class]]) {
        value = [(QCColorPort *)hoveredPort value];
      } else if ([hoveredPort isKindOfClass:[QCImagePort class]]) {
        value = [(QCImagePort *)hoveredPort imageValue];
      } else if ([hoveredPort isKindOfClass:[QCIndexPort class]]) {
        value = @([(QCIndexPort *)hoveredPort indexValue]);
      } else if ([hoveredPort isKindOfClass:[QCNumberPort class]]) {
        value = @([(QCNumberPort *)hoveredPort doubleValue]);
      } else if ([hoveredPort isKindOfClass:[QCProxyPort class]]) {
        value = [(QCProxyPort *)hoveredPort value];
      } else if ([hoveredPort isKindOfClass:[QCStringPort class]]) {
        value = [(QCStringPort *)hoveredPort stringValue];
      } else if ([hoveredPort isKindOfClass:[QCStructurePort class]]) {
        value = [(QCStructurePort *)hoveredPort structureValue];
      } else if ([hoveredPort isKindOfClass:[QCVirtualPort class]]) {
        value = [(QCVirtualPort *)hoveredPort rawValue];
      } else {
        NSLog(@"Did not recognize port type: %@", NSStringFromClass([hoveredPort class]));
      }
      
      if (!value) {
        return;
      }
      
      Class valueClass = [value class];
      
      if ([valueClass isSubclassOfClass:[QCImage class]]) {
        // QCImage
        value = [value createNSImageForManager:[QCImageManager sharedSoftwareImageManager] withOptions:0];
      } else if ([valueClass isSubclassOfClass:[QCStructure class]]) {
        // QCStructure
        value = [[value dictionaryRepresentation] description];
      } else if ([valueClass isSubclassOfClass:[NSColor class]]) {
        // NSColor
        value = [value description];
      } else if ([valueClass isSubclassOfClass:[NSNumber class]]) {
        // NSNumber
        value = [value stringValue];
      } else if ([valueClass isSubclassOfClass:[NSData class]]) {
        // NSData
        value = [[NSString alloc] initWithData:value encoding:NSUnicodeStringEncoding];
      } else if ([valueClass isSubclassOfClass:[NSString class]]) {
        // NSString
        value = value;
      } else if ([valueClass isSubclassOfClass:[NSImage class]]) {
        // NSImage
        value = value;
      } else if ([valueClass isSubclassOfClass:[NSDictionary class]]) {
        // NSDictionary
        value = [value description];
      } else {
        NSLog(@"Did not recognize value class: %@", NSStringFromClass(valueClass));
      }
      
      if (!value) {
        return;
      }
      
      NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
      [pasteboard clearContents];
      [pasteboard writeObjects:[NSArray arrayWithObject:value]];
    }
  }
  
  else if ([characters isEqualToString:@"m"]) {
    QCPatch *patch = [QCPatch createPatchWithName:@"QCMultiplexer"];
    
    BOOL isSourceIndexType = [FBOrigamiAdditions sharedAdditions].hoveredPort.valueClass == [NSNumber class];
    NSString *inputPortKey = nil;
    
    if (!isSourceIndexType) {
      inputPortKey = @"source_0";
      [patch performSelector:@selector(setPortClass:) withObject:[[FBOrigamiAdditions sharedAdditions].hoveredPort class]];
    }
    
    [[FBOrigamiAdditions sharedAdditions] insertPatch:patch inPatchView:patchView inputPortKey:inputPortKey outputPortKey:nil];
  }
  
  else if ([characters isEqualToString:@"k"]) {
    QCKeyboard *patch = (QCKeyboard *)[QCPatch createPatchWithName:@"QCKeyboard"];
    
    [patch setObservedKeys:[NSArray arrayWithObjects:@" ", nil]];
    
    [[FBOrigamiAdditions sharedAdditions] insertPatch:patch inPatchView:patchView];
  }
  
  else if ([characters isEqualToString:@"r"]) {
    [[FBOrigamiAdditions sharedAdditions] insertPatch:[QCPatch createPatchWithName:@"/reverse progress"] inPatchView:patchView];
  }
  
  else if ([characters isEqualToString:@"T"]) {
    QCPort *hoveredPort = [FBOrigamiAdditions sharedAdditions].hoveredPort;
    
    NSString *inputPortKey = nil;
    
    if (hoveredPort)
      inputPortKey = @"Text";
    
    QCPatch *textLayer = [QCPatch createPatchWithName:@"/text layer"];
    
    [[FBOrigamiAdditions sharedAdditions] insertPatch:textLayer inPatchView:patchView inputPortKey:inputPortKey outputPortKey:nil];
  }
  
  else if ([characters isEqualToString:@"t"]) {
    QCPort *hoveredPort = [FBOrigamiAdditions sharedAdditions].hoveredPort;
    QCPatch *patch;
    
    if (hoveredPort.baseClass == [QCColorPort class])
      patch = [QCPatch createPatchWithName:@"/color transition"];
    else if (hoveredPort.baseClass == [QCImagePort class])
      patch = [QCPatch createPatchWithName:@"/image transition"];
    else
      patch = [QCPatch createPatchWithName:@"/transition"];
    
    BOOL isHoveredOverInputPort = hoveredPort.fb_isInputPort;
    if (hoveredPort && isHoveredOverInputPort)
      [(QCPatch *)patch userInfo][@"name"] = hoveredPort.fb_name;
    
    NSString *inputPortKey = isHoveredOverInputPort ? @"Start_Value" : nil;
    [[FBOrigamiAdditions sharedAdditions] insertPatch:patch inPatchView:patchView inputPortKey:inputPortKey outputPortKey:nil];
  }
  
  else if ([characters isEqualToString:@"a"]) {
    [[FBOrigamiAdditions sharedAdditions] insertPatch:[QCPatch createPatchWithName:@"/pop animation"] inPatchView:patchView];
  }
  
  else if ([characters isEqualToString:@"d"]) {
    [[FBOrigamiAdditions sharedAdditions] insertPatch:[QCPatch createPatchWithName:@"FBODelayPatch"] inPatchView:patchView];
  }
  
  else if ([characters isEqualToString:@"l"]) {
    QCPort *hoveredPort = [FBOrigamiAdditions sharedAdditions].hoveredPort;
    NSString *inputPortKey;
    if (hoveredPort.baseClass == [QCImagePort class] || hoveredPort.baseClass == [QCVirtualPort class] || [hoveredPort.key isEqualToString:@"File"] || [hoveredPort.key isEqualToString:@"Image"]) {
      inputPortKey = @"Image";
    } else if (hoveredPort.baseClass == [QCColorPort class]) {
      inputPortKey = @"Color";
    }
    
    QCPatch *sprite = [QCPatch createPatchWithName:@"/layer"];
    
    if ([hoveredPort.node userInfo][@"name"])
      [(QCPatch *)sprite userInfo][@"name"] = [hoveredPort.node userInfo][@"name"];
    
    [[FBOrigamiAdditions sharedAdditions] insertPatch:sprite inPatchView:patchView inputPortKey:inputPortKey outputPortKey:nil];
  }
  
  else if ([characters isEqualToString:@"L"]) {
    [[FBOrigamiAdditions sharedAdditions] insertPatch:[QCPatch createPatchWithName:@"FBOLiveFilePatch"] inPatchView:patchView];
  }
  
  else if ([characters isEqualToString:@"h"]) {
    [[FBOrigamiAdditions sharedAdditions] insertPatch:[QCPatch createPatchWithName:@"/hit area"] inPatchView:patchView];
  }
  
  else if ([characters isEqualToString:@"H"] && FBToolsIsInstalled()) {
    QCPatch *hitTest = [QCPatch createPatchWithName:@"/hit test 2"];
    [[FBOrigamiAdditions sharedAdditions] insertPatch:hitTest inPatchView:patchView];
    
    QCPatch *hitTestRectangle = [QCPatch createPatchWithName:@"/hit test rectangle 2"];
    [[FBOrigamiAdditions sharedAdditions] insertPatch:hitTestRectangle inPatchView:patchView];
    
    QCPatch *billboard = [QCPatch createPatchWithName:@"QCBillboard"];
    [[FBOrigamiAdditions sharedAdditions] insertPatch:billboard inPatchView:patchView];
    
    hitTestRectangle.userInfo[@"position"] = [patchView fb_positionValueForPatchWithPort:[hitTestRectangle portForKey:@"Rectangle"] alignedToPort:[hitTest portForKey:@"Rectangle"]];
    
    billboard.userInfo[@"position"] = [patchView fb_positionValueForPatchWithPort:[billboard portForKey:@"inputPixelAligned"] alignedToPort:[hitTest portForKey:@"Tap"]];
    
    [[patchView graph] createConnectionFromPort:[hitTestRectangle portForKey:@"Rectangle"] toPort:[hitTest portForKey:@"Rectangle"]];
    [[patchView graph] createConnectionFromPort:[hitTest portForKey:@"Tap"] toPort:[billboard portForKey:@"inputPixelAligned"]];
  }
  
  else if ([characters isEqualToString:@"1"] && FBToolsIsInstalled() && !((QCPatch *)[FBOrigamiAdditions sharedAdditions].patchView.graph).parentPatch) {
    QCPatch *viewerSize = [QCPatch createPatchWithName:@"/viewer size"];
    [[FBOrigamiAdditions sharedAdditions] insertPatch:viewerSize inPatchView:patchView];
    
    QCPatch *renderInImage = [QCPatch createPatchWithName:@"QCRenderInImage"];
    renderInImage.userInfo[@"fb_isLayerGroup"] = @YES;
    [[FBOrigamiAdditions sharedAdditions] insertPatch:renderInImage inPatchView:patchView];
    
    QCPatch *fillLayer = [QCPatch createPatchWithName:@"/fill layer"];
    [[fillLayer portForKey:@"Alpha"] setDoubleValue:1.0];
    [renderInImage addSubpatch:fillLayer];
    NSSize fillLayerSize = fillLayer.fb_actorSize;
    NSPoint center = [patchView _centerPoint];
    fillLayer.userInfo[@"position"] = [NSValue valueWithPoint:NSMakePoint(center.x - fillLayerSize.width / 2.0, center.y - fillLayerSize.height / 2.0)];
      
    QCPatch *viewer = [QCPatch createPatchWithName:@"/viewer"];
    [[FBOrigamiAdditions sharedAdditions] insertPatch:viewer inPatchView:patchView];
    
    viewerSize.userInfo[@"position"] = [patchView fb_positionValueForPatchWithPort:[viewerSize portForKey:@"Pixels_Wide"] alignedToPort:[renderInImage portForKey:@"inputWidth"]];
    viewer.userInfo[@"position"] = [patchView fb_positionValueForPatchWithPort:[viewer portForKey:@"Image"] alignedToPort:[renderInImage portForKey:@"outputImage"]];
    
    [[patchView graph] createConnectionFromPort:[viewerSize portForKey:@"Pixels_Wide"] toPort:[renderInImage portForKey:@"inputWidth"]];
    [[patchView graph] createConnectionFromPort:[viewerSize portForKey:@"Pixels_High"] toPort:[renderInImage portForKey:@"inputHeight"]];
    [[patchView graph] createConnectionFromPort:[renderInImage portForKey:@"outputImage"] toPort:[viewer portForKey:@"Image"]];
  }
}

#pragma mark Return Key to Rename Patch

- (void)editNameOfSelectedPatchInPatchView:(QCPatchView *)patchView {
  NSArray *selectedNodes = [patchView.patch selectedNodes];
  
  if (selectedNodes.count != 1) {
    return;
  }
  
  QCPatch *patch = selectedNodes.lastObject;
  [FBOrigamiAdditions sharedAdditions].patchBeingEdited = patch;
  
  NSString *name = patch.fb_name;
  
  CGPoint point = [[[patch userInfo] objectForKey:@"position"] pointValue];
  point.y += 14;
  NSSize size = [patchView _sizeForNode:patch];
  
  BOOL success = [GFStringEditor runSharedEditorWithString:&name inView:patchView atPoint:point width:size.width numLines:1];
  
  if (success) {
    QCPatchActor *actor = [patchView nodeActorForNode:patch];
    [actor setTitle:name forNode:patch];
  }
}

#pragma mark Hover Over Port Actions

- (void)insertLogicInPatchView:(QCPatchView *)patchView type:(FBLogicOperation)operationIndex {
  QCPatch *logicPatch = [QCPatch createPatchWithName:@"QCLogic"];
  
  QCIndexPort *operationPort = [logicPatch portForKey:@"inputOperation"];
  operationPort.indexValue = operationIndex;
  
  [self insertPatch:logicPatch inPatchView:patchView];
}

- (void)insertMathInPatchView:(QCPatchView *)patchView type:(FBMathOperation)operationIndex {
  QCPatch *mathPatch = [QCPatch createPatchWithName:@"QCMath"];
  
  QCIndexPort *operationPort = (QCIndexPort *)[[mathPatch inputPorts] objectAtIndex:1];
  operationPort.indexValue = operationIndex;
  
  [self insertPatch:mathPatch inPatchView:patchView];
}

@end
