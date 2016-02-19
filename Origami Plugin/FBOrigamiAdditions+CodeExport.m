/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiAdditions+CodeExport.h"
#import "QCPatch+FBAdditions.h"
#import "QCPort+FBAdditions.h"

typedef enum {
  FBCodeTypeIOS,
  FBCodeTypeAndroid,
  FBCodeTypeWeb
} FBCodeType;

static NSMutableDictionary *variableNames; // Key: Local variable names. Value: Number of times it's used in the current scope
static FBCodeType codeType;
static NSUInteger transitionPatchCount;
static NSUInteger rotationPortCount;
static NSUInteger pixelPortCount;

@implementation FBOrigamiAdditions (CodeExport)

- (void)setupCodeExportMenuItems {
  NSMenuItem *export = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Code Export" action:NULL keyEquivalent:@""];
  NSMenu *exportMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""];
  [self.origamiMenu addItem:export];
  [self.origamiMenu setSubmenu:exportMenu forItem:export];
  
  NSMenuItem *iosMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"iOS" action:@selector(exportToIOS:) keyEquivalent:@"i"];
  iosMenuItem.keyEquivalentModifierMask = NSAlternateKeyMask|NSCommandKeyMask|NSControlKeyMask;
  [(id)iosMenuItem setTarget:self];
  [exportMenu addItem:iosMenuItem];

  NSMenuItem *androidMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Android" action:@selector(exportToAndroid:) keyEquivalent:@"a"];
  androidMenuItem.keyEquivalentModifierMask = NSAlternateKeyMask|NSCommandKeyMask|NSControlKeyMask;
  [(id)androidMenuItem setTarget:self];
  [exportMenu addItem:androidMenuItem];
  
  NSMenuItem *webMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Web" action:@selector(exportToWeb:) keyEquivalent:@"w"];
  webMenuItem.keyEquivalentModifierMask = NSAlternateKeyMask|NSCommandKeyMask|NSControlKeyMask;
  [(id)webMenuItem setTarget:self];
  [exportMenu addItem:webMenuItem];
  
  [exportMenu addItem:[NSMenuItem separatorItem]];
  
  NSMenuItem *helpMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Help" action:@selector(showHelp:) keyEquivalent:@""];
  [(id)helpMenuItem setTarget:self];
  [exportMenu addItem:helpMenuItem];
  
  variableNames = [NSMutableDictionary dictionary];
}

- (void)resetGlobalState {
  transitionPatchCount = 0;
  rotationPortCount = 0;
  pixelPortCount = 0;
  [variableNames removeAllObjects];
}

- (void)showHelp:(id)sender {
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://facebook.github.io/origami/documentation/concepts/CodeExport.html"]];
}

- (void)exportToIOS:(id)sender {
  codeType = FBCodeTypeIOS;
  
  [self resetGlobalState];
  
  QCPatch *rootNode = self.currentPatch.fb_rootPatch;
  NSArray *animationPatches = [rootNode findSubpatchesWithName:@"/pop animation" options:0];
  
  NSMutableString *fileString = [[NSMutableString alloc] initWithString:[self contentsOfSnippetNamed:@"Prefix" trailingNewLines:1]];
  
  [self writeSpringVariableDeclarationsToString:fileString];
  
  [fileString appendString:@"@end\n\n@implementation ViewController\n\n"];
  
  for (QCPatch *animationPatch in animationPatches) {
    [self writeSpringConfigurationToString:fileString animationPatch:animationPatch];
    [self writeSpringCallbackToString:fileString animationPatch:animationPatch];
  }
  
  [self writeHelperFunctionsToString:fileString];
  [self writeStringToFileAndOpen:fileString];
}

- (void)exportToAndroid:(id)sender {
  codeType = FBCodeTypeAndroid;
  
  [self resetGlobalState];
  
  QCPatch *rootNode = self.currentPatch.fb_rootPatch;
  NSArray *animationPatches = [rootNode findSubpatchesWithName:@"/pop animation" options:0];
  
  NSMutableString *fileString = [[NSMutableString alloc] initWithString:[self contentsOfSnippetNamed:@"Prefix" trailingNewLines:0]];
  
  [self writeSpringVariableDeclarationsToString:fileString];
  
  NSOrderedSet *layerNames = [self layerNames];
  
  for (NSString *layerName in layerNames) {
    [fileString appendFormat:@"  private final View %@;\n",layerName];
  }
  
  [fileString appendString:@"\n"];
  [fileString appendString:[self contentsOfSnippetNamed:@"MiddleSection" trailingNewLines:1]];
  
  for (NSString *layerName in layerNames) {
    [fileString appendFormat:@"    %@ = null;\n",layerName];
  }
  
  [fileString appendString:@"\n"];
  [fileString appendString:@"    springSystem = SpringSystem.create();\n"];
  
  for (QCPatch *animationPatch in animationPatches) {
    [self writeSpringConfigurationToString:fileString animationPatch:animationPatch];
  }
  
  [fileString appendString:@"  }\n\n"];
  
  for (QCPatch *animationPatch in animationPatches) {
    [self writeSpringCallbackToString:fileString animationPatch:animationPatch];
  }
  
  [self writeHelperFunctionsToString:fileString];
  [self writeStringToFileAndOpen:fileString];
}

- (void)exportToWeb:(id)sender {
  codeType = FBCodeTypeWeb;
  
  [self resetGlobalState];
  
  QCPatch *rootNode = self.currentPatch.fb_rootPatch;
  NSArray *animationPatches = [rootNode findSubpatchesWithName:@"/pop animation" options:0];
  
  NSMutableString *fileString = [[NSMutableString alloc] initWithString:[self contentsOfSnippetNamed:@"Prefix" trailingNewLines:2]];
  
  for (QCPatch *animationPatch in animationPatches) {
    [self writeSpringConfigurationToString:fileString animationPatch:animationPatch];
    [self writeSpringCallbackToString:fileString animationPatch:animationPatch];
  }
  
  NSOrderedSet *layerNames = [self layerNames];
  
  if (layerNames.count > 0) {
    NSString *layerHookupWrapper = [self contentsOfSnippetNamed:@"LayerHookup" trailingNewLines:2];
    
    NSMutableString *layerHookupContents = [[NSMutableString alloc] initWithString:@""];
    
    NSUInteger itemIndex = 0;
    for (NSString *layerName in layerNames) {
      NSString *layerHookupItem = [self contentsOfSnippetNamed:@"LayerHookupItem" trailingNewLines:0];
      [layerHookupContents appendFormat:layerHookupItem,layerName];
      
      if (layerNames.count > 1 && itemIndex < (layerNames.count - 1))
        [layerHookupContents appendString:@",\n\n"];
      else
        [layerHookupContents appendString:@"\n"];
      
      itemIndex++;
    }
    
    [fileString appendFormat:layerHookupWrapper,layerHookupContents];
  }
  
  [self writeHelperFunctionsToString:fileString];
  [self writeStringToFileAndOpen:fileString];
}

- (NSString *)uppercaseFirstLetterOfString:(NSString *)string {
  string = [NSString stringWithFormat:@"%@%@",[[string substringToIndex:1] uppercaseString],[string substringFromIndex:1]];
  return string;
}

- (NSString *)lowercaseFirstLetterOfString:(NSString *)string {
  string = [NSString stringWithFormat:@"%@%@",[[string substringToIndex:1] lowercaseString],[string substringFromIndex:1]];
  return string;
}

- (NSString *)camelCaseString:(NSString *)string {
  NSString *newString = [string capitalizedString];
  newString = [self lowercaseFirstLetterOfString:newString];
  newString = [newString stringByReplacingOccurrencesOfString:@" " withString:@""];
  return newString;
}

- (NSString *)nameForAnimationPatch:(QCPatch *)patch {
  NSString *patchName = patch.userInfo[@"name"];
  
  if (!patchName) {
    // If it's downstream from a custom named switch patch, use that name
    QCPort *inputPort = patch.inputPorts[0];
    QCPort *connectedPort = inputPort.fb_connectedPorts[0];
    QCPatch *connectedPatch = connectedPort.parentPatch;
    
    NSString *customName = connectedPatch.userInfo[@"name"];
    if ([connectedPatch.fb_className isEqualToString:@"/switch"] && customName) {
      patchName = customName;
    }
    // Otherwise use whatever name we can get
    else {
      patchName = patch.fb_name;
    }
  }
  
  return [self camelCaseString:patchName];
}

- (BOOL)patchIsKindOfLayer:(QCPatch *)patch {
  return [patch.fb_className hasSuffix:@"layer"];
}

- (NSString *)variableNameForPatch:(QCPatch *)patch {
  NSString *patchName = [self camelCaseString:patch.fb_name];
  
  if (variableNames[patchName]) {
    NSUInteger count = ((NSNumber *)variableNames[patchName]).unsignedIntegerValue;
    NSUInteger newCount = count+1;
    patchName = [patchName stringByAppendingString:[NSString stringWithFormat:@"%lu",newCount]];
    variableNames[patchName] = @(newCount);
  }
  else {
    variableNames[patchName] = @(1);
  }
  
  return patchName;
}

- (void)writeSpringVariableDeclarationsToString:(NSMutableString *)fileString {
  QCPatch *rootNode = self.currentPatch.fb_rootPatch;
  NSArray *animationPatches = [rootNode findSubpatchesWithName:@"/pop animation" options:0];
  
  for (QCPatch *animationPatch in animationPatches) {
    NSString *animationName = [self nameForAnimationPatch:animationPatch];
    
    if (codeType == FBCodeTypeIOS)
      [fileString appendFormat:@"@property (nonatomic) CGFloat %@Progress;\n",animationName];
    else if (codeType == FBCodeTypeAndroid)
      [fileString appendFormat:@"  private final Spring %@Spring;\n",animationName];
  }
}

- (void)writeSpringConfigurationToString:(NSMutableString *)fileString animationPatch:(QCPatch *)animationPatch {
  NSString *animationName = [self nameForAnimationPatch:animationPatch];
  NSString *titleCasedAnimationName = [self uppercaseFirstLetterOfString:animationName];
  NSNumber *bounciness = ((QCPort *)[animationPatch portForKey:@"Bounciness"]).value;
  NSNumber *speed = ((QCPort *)[animationPatch portForKey:@"Speed"]).value;
  
  NSUInteger newLines = (codeType == FBCodeTypeAndroid) ? 1 : 2;
  NSString *springConfiguration = [self contentsOfSnippetNamed:@"SpringSetup" trailingNewLines:newLines];
  
  if (codeType == FBCodeTypeWeb) {
    [fileString appendFormat:springConfiguration,animationName,animationName,bounciness,speed,titleCasedAnimationName,animationName,animationName];
  }
  else if (codeType == FBCodeTypeAndroid) {
    [fileString appendString:@"\n"];
    [fileString appendFormat:springConfiguration,animationName,bounciness,speed,titleCasedAnimationName];
  }
  else if (codeType == FBCodeTypeIOS) {
    [fileString appendFormat:springConfiguration,animationName,titleCasedAnimationName,animationName,bounciness,speed,animationName,animationName,animationName,animationName];
  }
}

// An ordered set of camel cased layer names for all layers being animated in the composition.

- (NSOrderedSet *)layerNames {
  QCPatch *rootNode = self.currentPatch.fb_rootPatch;
  NSArray *animationPatches = [rootNode findSubpatchesWithName:@"/pop animation" options:0];
  
  NSMutableOrderedSet *allLayerNames = [[NSMutableOrderedSet alloc] init];
 
  for (QCPatch *animationPatch in animationPatches) {
    NSOrderedSet *layerNames = [self springCallbackContentsForAnimationPatch:animationPatch][@"layerNames"];
    [allLayerNames unionOrderedSet:layerNames];
  }
  
  return [NSOrderedSet orderedSetWithOrderedSet:allLayerNames];
}

//
// Traverses through the patches downstream from the animation patch and returns a dictionary with two keys:
//
//       "string"   A string with the written contents of the spring callback function.
//   "layerNames"   An ordered set of camel cased layer names being animated by this patch.
//

- (NSDictionary *)springCallbackContentsForAnimationPatch:(QCPatch *)animationPatch {
  NSMutableString *springCallbackContents = [[NSMutableString alloc] init];
  NSMutableOrderedSet *layerNames = [[NSMutableOrderedSet alloc] init];
  
  QCPort *outputPort = animationPatch.outputPorts[0];
  for (QCPort *portConnectedToAnimationOutput in outputPort.fb_connectedPorts) {
    QCPatch *patchConnectedToAnimationOutput = portConnectedToAnimationOutput.parentPatch;
    
    BOOL connectedToTransitionPatch = [patchConnectedToAnimationOutput.fb_className isEqualToString:@"/transition"];
    BOOL connectedToLayerPatch = [self patchIsKindOfLayer:patchConnectedToAnimationOutput];
    
    if (connectedToTransitionPatch) {
      QCPatch *transitionPatch = patchConnectedToAnimationOutput;
      NSString *transitionPatchName = [self writeTransitionAssignmentToString:springCallbackContents withTransitionPatch:transitionPatch];
      
      for (QCPort *portConnectedToTransitionOutput in ((QCPort *)transitionPatch.outputPorts[0]).fb_connectedPorts) {
        if ([self patchIsKindOfLayer:portConnectedToTransitionOutput.parentPatch]) {
          [self writeLayerPortSetterToString:springCallbackContents withPort:portConnectedToTransitionOutput variable:transitionPatchName];
          NSString *layerName = [self camelCaseString:portConnectedToTransitionOutput.parentPatch.fb_name];
          [layerNames addObject:layerName];
        }
      }
    }
    else if (connectedToLayerPatch) {
      [self writeLayerPortSetterToString:springCallbackContents withPort:portConnectedToAnimationOutput variable:@"progress"];
      NSString *layerName = [self camelCaseString:patchConnectedToAnimationOutput.fb_name];
      [layerNames addObject:layerName];
    }
  }
  
  NSDictionary *dictionary = @{ @"string" : [NSString stringWithString:springCallbackContents],
                                @"layerNames" : [NSOrderedSet orderedSetWithOrderedSet:layerNames] };
  return dictionary;
}

// Writes the entire spring callback function to the supplied string
- (void)writeSpringCallbackToString:(NSMutableString *)fileString animationPatch:(QCPatch *)animationPatch {
  NSString *springCallback = [self contentsOfSnippetNamed:@"SpringCallback" trailingNewLines:2];
  NSString *springCallbackContents = [self springCallbackContentsForAnimationPatch:animationPatch][@"string"];
  NSString *animationName = [self nameForAnimationPatch:animationPatch];
  NSString *titleCasedAnimationName = [self uppercaseFirstLetterOfString:animationName];
  
  if (codeType == FBCodeTypeIOS)
    [fileString appendFormat:springCallback,titleCasedAnimationName,animationName,springCallbackContents];
  else if (codeType == FBCodeTypeAndroid)
    [fileString appendFormat:springCallback,animationName,animationName,animationName,titleCasedAnimationName,springCallbackContents];
  else if (codeType == FBCodeTypeWeb)
    [fileString appendFormat:springCallback,titleCasedAnimationName,springCallbackContents];
}

// Write the code that translates the Transition patch with hard coded values to a variable.
- (NSString *)writeTransitionAssignmentToString:(NSMutableString *)fileString withTransitionPatch:(QCPatch *)transitionPatch {
  NSString *transitionPatchName = [self variableNameForPatch:transitionPatch];
  NSNumber *startValue = ((QCPort *)[transitionPatch portForKey:@"Start_Value"]).value;
  NSNumber *endValue = ((QCPort *)[transitionPatch portForKey:@"End_Value"]).value;
  
  NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
  [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
  [formatter setMaximumFractionDigits:4];
  NSString *startValueString = [formatter stringFromNumber:startValue];
  NSString *endValueString = [formatter stringFromNumber:endValue];
  
  if (codeType == FBCodeTypeWeb) {
    [fileString appendFormat:@"\n  var %@ = transition(progress, %@, %@);\n",transitionPatchName,startValueString,endValueString];
  }
  else if (codeType == FBCodeTypeAndroid) {
    [fileString appendFormat:@"\n    float %@ = transition(progress, %@f, %@f);\n",transitionPatchName,startValueString,endValueString];
  }
  else if (codeType == FBCodeTypeIOS) {
    [fileString appendFormat:@"\n\tCGFloat %@ = POPTransition(progress, %@, %@);\n",transitionPatchName,startValueString,endValueString];
  }

  transitionPatchCount++;
  
  return transitionPatchName;
}

// Write the code that assigns the temporary variable from the Transition patch to the layer property, or the progress variable directly if there is no Transition patch connected.
- (void)writeLayerPortSetterToString:(NSMutableString *)fileString withPort:(QCPort *)layerPort variable:(NSString *)variable {
  NSString *layerPortName = [self camelCaseString:layerPort.fb_name];
  NSString *layerName = [self camelCaseString:layerPort.parentPatch.fb_name];
  
  if (codeType == FBCodeTypeWeb) {
    layerPortName = [layerPortName isEqualToString:@"alpha"] ? @"opacity" : layerPortName;
    [fileString appendFormat:@"  layers.%@.%@ = %@;\n",layerName,layerPortName,variable];
  }
  else if (codeType == FBCodeTypeAndroid) {
    NSString *titleCasedLayerPortName = [self uppercaseFirstLetterOfString:layerPortName];
    
    if ([layerPortName hasSuffix:@"Position"]) {
      NSString *axis = [[layerPortName substringToIndex:1] uppercaseString];
      [fileString appendFormat:@"    %@.setTranslation%@(%@);\n",layerName,axis,variable];
    }
    else if ([layerPortName hasSuffix:@"Rotation"]) {
      NSString *axis = [[layerPortName substringToIndex:1] uppercaseString];
      if ([axis isEqualToString:@"Z"])
        axis = @"";
      
      [fileString appendFormat:@"    %@.setRotation%@(%@);\n",layerName,axis,variable];
    }
    else if ([layerPortName isEqualToString:@"scale"]) {
      [fileString appendFormat:@"    %@.setScaleX(%@);\n",layerName,variable];
      [fileString appendFormat:@"    %@.setScaleY(%@);\n",layerName,variable];
    }
    else {
      [fileString appendFormat:@"    %@.set%@(%@);\n",layerName,titleCasedLayerPortName,variable];
    }
  }
  else if (codeType == FBCodeTypeIOS) {
    layerPortName = [layerPortName isEqualToString:@"alpha"] ? @"opacity" : layerPortName;

    if ([layerPortName hasSuffix:@"Position"]) {
      NSString *axis = [[layerPortName substringToIndex:1] uppercaseString];
      NSString *minus = [axis isEqualToString:@"Y"] ? @"-" : @""; // Account for the flipped coordinate system in QC relative to CA / CSS
      [fileString appendFormat:@"\tPOPLayerSetTranslation%@(self.%@.layer, POPPixelsToPoints(%@%@));\n",axis,layerName,minus,variable];
      pixelPortCount++;
    }
    else if ([layerPortName hasSuffix:@"Rotation"]) {
      NSString *axis = [[layerPortName substringToIndex:1] uppercaseString];
      [fileString appendFormat:@"\tPOPLayerSetRotation%@(self.%@.layer, POPDegreesToRadians(%@));\n",axis,layerName,variable];
      rotationPortCount++;
    }
    else if ([layerPortName isEqualToString:@"scale"]) {
      [fileString appendFormat:@"\tPOPLayerSetScaleXY(self.%@.layer, CGPointMake(%@, %@));\n",layerName,variable,variable];
    }
    else if ([layerPortName isEqualToString:@"width"] || [layerPortName isEqualToString:@"height"]) { // TODO: Gonna have to make a CGRect here for bounds
//      [fileString appendFormat:@"\tself.%@.layer.\n",axis,layerName,variable]];
      // Use POPPixelsToPoints() here
      pixelPortCount++;
    }
    else {
      [fileString appendFormat:@"\tself.%@.layer.%@ = %@;\n",layerName,layerPortName,variable];
    }
  }
}

- (void)writeHelperFunctionsToString:(NSMutableString *)fileString {
  if (codeType == FBCodeTypeAndroid)
    [fileString appendString:@"  "];
  
  [fileString appendString:@"// Utilities\n\n"];
  
  if (transitionPatchCount > 0)
    [fileString appendString:[self contentsOfSnippetNamed:@"TransitionFunction" trailingNewLines:2]];
  
  if (rotationPortCount > 0)
    [fileString appendString:[self contentsOfSnippetNamed:@"DegreesToRadiansFunction" trailingNewLines:2]];
  
  if (pixelPortCount > 0)
    [fileString appendString:[self contentsOfSnippetNamed:@"PixelsToPointsFunction" trailingNewLines:2]];
  
  [fileString appendString:[self contentsOfSnippetNamed:@"Suffix" trailingNewLines:2]];
}

- (void)writeStringToFileAndOpen:(NSMutableString *)fileString {
  NSArray *urls = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
  NSURL *desktopURL = urls[0];

  NSString *fileName = @"code.js";
  
  if (codeType == FBCodeTypeIOS)
    fileName = @"ViewController.m";
  else if (codeType == FBCodeTypeAndroid)
    fileName = @"OrigamiAnimationView.java";
  
  desktopURL = [desktopURL URLByAppendingPathComponent:fileName];
  [fileString writeToURL:desktopURL atomically:YES encoding:NSUnicodeStringEncoding error:nil];
  [[NSWorkspace sharedWorkspace] openURL:desktopURL];
}

- (NSString *)contentsOfSnippetNamed:(NSString *)name trailingNewLines:(NSUInteger)newLines {
  NSString *resourceName = [NSString stringWithFormat:@"Code Export/%@",name];
  
  NSString *fileExtension = @"js";
  if (codeType == FBCodeTypeIOS)
    fileExtension = @"m";
  else if (codeType == FBCodeTypeAndroid)
    fileExtension = @"java";
  
  NSString *filePath = [[FBOrigamiAdditions origamiBundle] pathForResource:resourceName ofType:fileExtension];
  
  if (!filePath)
    return @"";
  
  NSString *string = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
  
  for (int i = 0; i < newLines; i++) {
    string = [string stringByAppendingString:@"\n"];
  }
  
  return string;
}

@end
