/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiAdditions+FileCreation.h"
#import "FBOLiveFilePatch.h"
#import "QCPatch+FBAdditions.h"
#import "QCPatchView+FBAdditions.h"

BOOL importingFromSketch = NO;
NSString *sketchFilename;
NSWindowController *controller;
QCPatchView *patchView;
QCPatch *templateRII;
QCPatch *devicePicker;
NSWindow *progressWindow;

@implementation FBOrigamiAdditions (FileCreation)

NSProgressIndicator *_progressIndicator;

- (void)newOrigamiFile:(id)sender {
  NSError* error;
  id document = [[NSClassFromString(@"MyDocumentController") sharedDocumentController] openUntitledDocumentAndDisplay:YES error:&error];

  [self performSelector:@selector(addTemplatePatchesToDocument:) withObject:document afterDelay:0];
}

- (void)importSketchFile:(id)sender {
  // Prompt for Sketch file
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  [openPanel setTitle:@"Pick a .sketch file to import."];
  [openPanel setPrompt:@"Import"];
  [openPanel setCanChooseDirectories:NO];
  [openPanel setAllowsMultipleSelection:NO];
  [openPanel setAllowedFileTypes:@[@"sketch"]];
  NSInteger result = [openPanel runModal];
  NSString *sketchPath;
  if(result == NSOKButton) {
    sketchPath = [[openPanel URL] path];
    sketchFilename = [[openPanel URL] lastPathComponent];
  } else { return; }

  // Open file in Sketch
  NSTask *task = [[NSTask alloc] init];
  task.launchPath = @"/usr/bin/open";
  task.arguments = @[sketchPath];
  [task launch];

  [self focusAppWithIdentifier:@"QuartzComposer"];

  // Create new file and place imported layers
  NSError* error;
  id document = [[NSClassFromString(@"MyDocumentController") sharedDocumentController] openUntitledDocumentAndDisplay:YES error:&error];

  [self performSelector:@selector(addTemplatePatchesToDocumentFromSketch:) withObject:document afterDelay:0];
}

- (void)addTemplatePatchesToDocument:(id)document {
  [self addTemplatePatchesToDocument:document fromSketch:NO];
}

- (void)addTemplatePatchesToDocumentFromSketch:(id)document {
  [self addTemplatePatchesToDocument:document fromSketch:YES];
}

- (void)addTemplatePatchesToDocument:(id)document fromSketch:(BOOL)fromSketch {
  controller = [document performSelector:@selector(editorController)];
  QCPatchEditorView *editingView = [controller performSelector:@selector(editingView)];
  patchView = [editingView graphView];
  
  QCPatch *phone = [QCPatch createPatchWithName:@"/viewer"];
  [[FBOrigamiAdditions sharedAdditions] insertPatch:phone inPatchView:patchView];
  
  QCPatch *renderInImage = [QCPatch createPatchWithName:@"QCRenderInImage"];
  renderInImage.userInfo[@"fb_isLayerGroup"] = @YES;
  [[FBOrigamiAdditions sharedAdditions] insertPatch:renderInImage inPatchView:patchView];
  
  devicePicker = [QCPatch createPatchWithName:@"/viewer size"];
  [[FBOrigamiAdditions sharedAdditions] insertPatch:devicePicker inPatchView:patchView];
  
  QCPatch *fillLayer = [QCPatch createPatchWithName:@"/fill layer"];
  [[fillLayer portForKey:@"Alpha"] setDoubleValue:1.0];
  [renderInImage addSubpatch:fillLayer];
  
  NSPoint fillPosition = [patchView _centerPoint];
  NSSize fillSize = fillLayer.fb_actorSizeInKeyPatchView;
  fillPosition.x -= roundf(fillSize.width / 2.0);
  fillPosition.y -= roundf(fillSize.height / 2.0);
  fillLayer.userInfo[@"position"] = [NSValue valueWithPoint:fillPosition];
  
  NSPoint position2 = [patchView _centerPoint];
  NSSize actorSize = renderInImage.fb_actorSizeInKeyPatchView;
  position2.x -= roundf(actorSize.width / 2.0);
  position2.y -= roundf(actorSize.height / 2.0);
  renderInImage.userInfo[@"position"] = [NSValue valueWithPoint:position2];
  
  devicePicker.userInfo[@"position"] = [patchView fb_positionValueForPatchWithPort:[devicePicker portForKey:@"Pixels_Wide"] alignedToPort:[renderInImage portForKey:@"inputWidth"]];
  
  QCPort *viewerImagePort = [phone portForKey:@"Screen_Image"];
  if (!viewerImagePort)
    viewerImagePort = [phone portForKey:@"Image"];
  
  phone.userInfo[@"position"] = [patchView fb_positionValueForPatchWithPort:viewerImagePort alignedToPort:[renderInImage portForKey:@"outputImage"]];
  
  [[patchView graph] createConnectionFromPort:[devicePicker portForKey:@"Pixels_Wide"] toPort:[renderInImage portForKey:@"inputWidth"]];
  [[patchView graph] createConnectionFromPort:[devicePicker portForKey:@"Pixels_High"] toPort:[renderInImage portForKey:@"inputHeight"]];
  [[patchView graph] createConnectionFromPort:[renderInImage portForKey:@"outputImage"] toPort:viewerImagePort];
  
  [patchView fb_setSelected:NO forPatch:phone];
  [patchView fb_setSelected:NO forPatch:renderInImage];
  [patchView fb_setSelected:NO forPatch:devicePicker];
  
  templateRII = renderInImage;

  if (fromSketch) {
    // Start progress indicator on window
    NSWindowController *controller = [document performSelector:@selector(editorController)];
    NSString *message = [NSString stringWithFormat:@"Importing %@", sketchFilename];
    progressWindow = [self progressIndicatorWithMessage:message];
    [controller.window beginSheet:progressWindow completionHandler:nil];

    // Run Export for Origami.js and get exported path
    NSTask *exportSketch = [self setupCocoaScript:@"Export for Origami.js"];
    NSPipe *exportSketchPathPipe = [NSPipe pipe];
    exportSketch.standardOutput = exportSketchPathPipe;

    __block __weak id exportSketchObserver;
    exportSketchObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSTaskDidTerminateNotification
                                                      object:exportSketch
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *notif){
      // End progress indicator
      [controller.window endSheet:progressWindow];
      [self addSketchPatchesToDocumentFromPath:[self getCocoaScriptOutput:exportSketchPathPipe]];

      // Remove observer
      [[NSNotificationCenter defaultCenter] removeObserver:exportSketchObserver];
    }];

    [exportSketch launch];
  }
}

- (NSTask *)setupCocoaScript:(NSString *)scriptName {
  NSString *exePath = [[[FBOrigamiAdditions origamiBundle] resourcePath] stringByAppendingPathComponent:@"coscript"];
  NSString *jsPath = [[[FBOrigamiAdditions origamiBundle] resourcePath] stringByAppendingPathComponent:scriptName];
  NSTask *task = [[NSTask alloc] init];
  task.launchPath = @"/usr/bin/env";
  task.arguments = @[exePath, jsPath];
  return task;
}

- (NSString *)getCocoaScriptOutput:(NSPipe *)pipe {
  NSFileHandle * read = [pipe fileHandleForReading];
  NSData * dataRead = [read readDataToEndOfFile];
  NSString * exportPath = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
  return [exportPath stringByReplacingOccurrencesOfString:@"\n" withString:@""];
}

- (void)addSketchPatchesToDocumentFromPath:(NSString *)exportPath {
  // Get export data.json with layer info
  NSMutableString *dataPath = [[NSMutableString alloc] initWithString:exportPath];
  [dataPath appendString:@"/data.json"];
  NSError *error = nil;
  NSData *data = [NSData dataWithContentsOfFile:dataPath options:nil error:&error];

  if (!error) {
    // Metadata for layers
    NSDictionary *metadata = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

    // New progress indicator for placing layers, the heaviest part
    NSString *message = [NSString stringWithFormat:@"Placing %@ layers into Layer Group...", metadata[@"layer_count"]];
    progressWindow = [self progressIndicatorWithMessage:message];
    [controller.window beginSheet:progressWindow completionHandler:nil];

    // Set devicePicker based on first layer
    [self setDevicePickerWithWidth:[metadata[@"layers"][0][@"w"] unsignedIntegerValue]];

    int i = 0;
    for (NSDictionary *layer in metadata[@"layers"]) {
      NSString *currentPath = exportPath;
      [currentPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
      currentPath = [currentPath stringByAppendingPathComponent:layer[@"name"]];
    
      NSMutableDictionary *mutableLayer = [layer mutableCopy];
      [mutableLayer setValue:@{@"x":@"0", @"y":@"0", @"w":@([layer[@"w"] unsignedIntegerValue]), @"h":@([layer[@"h"] unsignedIntegerValue])} forKey:@"parent"];
      [mutableLayer setValue:@(i++) forKey:@"order"];
      [self placeLayer:mutableLayer inGroup:templateRII inPatchView:patchView withPath:currentPath];
    }

    // End progress indicator
    [controller.window endSheet:progressWindow];
  }
  
  return;
}


- (void)setDevicePickerWithWidth:(NSUInteger)w {
  // Key:           w     h
  // 0: iPhone5     640   1136
  // 1: Android     720   1280
  // 2: WinPho      480   800
  // 3: iPad        1536  2048
  // 4: iPhone6     750   1334
  // 5: iPhone6+    1242  2208
  // 6: Apple Watch 320   400

  NSUInteger deviceIndex;

  switch (w) {
    case 640:
      deviceIndex = 0;
      break;

    case 720:
      deviceIndex = 1;
      break;

    case 480:
      deviceIndex = 2;
      break;

    case 1536:
      deviceIndex = 3;
      break;

    case 750:
      deviceIndex = 4;
      break;

    case 1242:
      deviceIndex = 5;
      break;

    case 320:
      deviceIndex = 6;
      break;

    default:
      deviceIndex = 4;
      break;
  }

  [[devicePicker portForKey:@"Type"] setIndexValue:deviceIndex];
}

- (void)placeLayer:(NSDictionary *)layer inGroup:(QCPatch *)parentRII inPatchView:(QCPatchView *)patchView withPath:(NSString *)path {
  NSDictionary *parent = layer[@"parent"];
  double parentX = [parent[@"x"] doubleValue];
  double parentY = [parent[@"y"] doubleValue];
  double parentW = [parent[@"w"] doubleValue];
  double parentH = [parent[@"h"] doubleValue];

  NSString *layerName = layer[@"name"];
  NSUInteger index = [layer[@"order"] unsignedIntegerValue];
  double x = [layer[@"x"] doubleValue];
  double y = [layer[@"y"] doubleValue];
  double w = [layer[@"w"] doubleValue];
  double h = [layer[@"h"] doubleValue];

  // Convert to Center Anchor, QC coordinate system
  double convertedXPos = x - parentX + w/2 - parentW/2;
  double convertedYPos = -(y - parentY + h/2 - parentH/2);

  double fillLayerHeight = 160.0f;
  double patchVPadding = 20.0f;

  if ([layer[@"type"] isEqual: @"group"]) {
    QCPatch *groupLayer = [QCPatch createPatchWithName:@"/layer"];
    [[groupLayer portForKey:@"X_Position"] setDoubleValue:convertedXPos];
    [[groupLayer portForKey:@"Y_Position"] setDoubleValue:convertedYPos];
    if ([layer[@"hidden"] boolValue]) {
      [[groupLayer portForKey:@"_enable"] setBooleanValue:NO];
    }
    [parentRII addSubpatch:groupLayer];
    
    QCPatch *groupRII = [QCPatch createPatchWithName:@"QCRenderInImage"];
    groupRII.userInfo[@"fb_isLayerGroup"] = @YES;
    [[groupRII portForKey:@"inputWidth"] setIndexValue:w];
    [[groupRII portForKey:@"inputHeight"] setIndexValue:h];
    [parentRII addSubpatch:groupRII];

    NSPoint artboardPosition = [patchView _centerPoint];
    NSSize actorSize = groupLayer.fb_actorSizeInKeyPatchView;
    artboardPosition.x -= roundf(actorSize.width / 2.0);
    artboardPosition.y -= roundf((actorSize.height / 2.0) + (index * (actorSize.height + patchVPadding)) + fillLayerHeight);
    groupLayer.userInfo[@"position"] = [NSValue valueWithPoint:artboardPosition];
    groupRII.userInfo[@"position"] = [patchView fb_positionValueForPatchWithPort:[groupRII portForKey:@"outputImage"] alignedToPort:[groupLayer portForKey:@"Image"]];
    
    groupLayer.userInfo[@"name"] = layerName;
    groupRII.userInfo[@"name"] = layerName;
    
    [parentRII createConnectionFromPort:[groupRII portForKey:@"outputImage"] toPort:[groupLayer portForKey:@"Image"]];

    // Recursively loop thru layers within group
    int i = 0;
    for (NSDictionary *childLayer in [layer[@"layers"] reverseObjectEnumerator]) {
      NSMutableDictionary *mutableChildLayer = [childLayer mutableCopy];
      [mutableChildLayer setValue:@(i++) forKey:@"order"];
      [mutableChildLayer setValue:layer forKey:@"parent"];
      [self placeLayer:mutableChildLayer inGroup:groupRII inPatchView:patchView withPath:path];
    }
  } else if ([layer[@"type"] isEqual: @"layer"]) {
    QCPatch *layerPatch = [QCPatch createPatchWithName:@"/layer"];
    [[layerPatch portForKey:@"X_Position"] setDoubleValue:convertedXPos];
    [[layerPatch portForKey:@"Y_Position"] setDoubleValue:convertedYPos];
    if ([layer[@"hidden"] boolValue]) {
      [[layerPatch portForKey:@"_enable"] setBooleanValue:NO];
    }
    [parentRII addSubpatch:layerPatch];
    
    FBOLiveFilePatch *liveFilePatch = (FBOLiveFilePatch *)[QCPatch createPatchWithName:@"FBOLiveFilePatch"];
    NSString *liveImagePath = path;
    liveImagePath = [liveImagePath stringByAppendingPathComponent:layerName];
    liveImagePath = [liveImagePath stringByAppendingPathExtension:@"png"];
    [liveFilePatch setPathString:liveImagePath];
    QCPatch *liveImagePatch = liveFilePatch;
    [parentRII addSubpatch:liveImagePatch];
    
    NSPoint position = [patchView _centerPoint];
    NSSize actorSize = layerPatch.fb_actorSizeInKeyPatchView;
    position.x -= roundf(actorSize.width / 2.0);
    position.y -= roundf(actorSize.height / 2.0) + ((index+0.5) * (actorSize.height + patchVPadding));
    layerPatch.userInfo[@"position"] = [NSValue valueWithPoint:position];
    liveImagePatch.userInfo[@"position"] = [patchView fb_positionValueForPatchWithPort:liveImagePatch.outputPorts[0] alignedToPort:[layerPatch portForKey:@"Image"]];
    
    [parentRII createConnectionFromPort:liveImagePatch.outputPorts[0] toPort:[layerPatch portForKey:@"Image"]];
    
    layerPatch.userInfo[@"name"] = layerName;
    liveImagePatch.userInfo[@"name"] = layerName;
  }
}

- (NSWindow *)progressIndicatorWithMessage:(NSString *)message {
  float w = 400;
  float hPad = 30;
  NSRect frame=NSMakeRect(0,0,w,80);
  NSRect bar=NSMakeRect(hPad,20,(w - hPad*2),10);
  NSRect text=NSMakeRect(hPad,40,(w - hPad*2),20);
  NSTextField *textField = [[NSTextField alloc] initWithFrame:text];
  [textField setBezeled:NO];
  [textField setDrawsBackground:NO];
  [textField setEditable:NO];
  [textField setSelectable:NO];
  [textField setStringValue:message];
  NSView *view = [[NSView alloc] initWithFrame:frame];
  _progressIndicator =[[NSProgressIndicator alloc] initWithFrame:bar];
  [view addSubview:_progressIndicator];
  [view addSubview:textField];
  
  NSWindow *progressWindow;
  progressWindow=[[NSWindow alloc]
                  initWithContentRect:frame
                  styleMask:NSBorderlessWindowMask
                  backing:NSBackingStoreBuffered
                  defer:NO];
  [progressWindow setContentView:view];
  [_progressIndicator setIndeterminate:YES];
  [_progressIndicator setUsesThreadedAnimation:YES];
  [_progressIndicator startAnimation:nil];

  return progressWindow;
}

- (void)focusAppWithIdentifier:(NSString *)identifier {
  NSArray *apps = [[NSWorkspace sharedWorkspace] runningApplications];
  [apps enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSRunningApplication *app = [apps objectAtIndex:idx];
    if([app bundleIdentifier] && [[app bundleIdentifier] containsString:identifier]) {
      [app activateWithOptions:NSApplicationActivateIgnoringOtherApps];
    }
  }];
}

@end
