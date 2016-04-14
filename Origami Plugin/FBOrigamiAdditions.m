/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiAdditions.h"
#import "FBOrigamiAdditions+CodeExport.h"
#import "FBOrigamiAdditions+DimDisabledConsumers.h"
#import "FBOrigamiAdditions+DragAndDrop.h"
#import "FBOrigamiAdditions+FileCreation.h"
#import "FBOrigamiAdditions+InlineValues.h"
#import "FBOrigamiAdditions+KeyboardShortcuts.h"
#import "FBOrigamiAdditions+LinearPortConnections.h"
#import "FBOrigamiAdditions+Mavericks.h"
#import "FBOrigamiAdditions+PatchMenu.h"
#import "FBOrigamiAdditions+PluginLoading.h"
#import "FBOrigamiAdditions+Preferences.h"
#import "FBOrigamiAdditions+RenderInImage.h"
#import "FBOrigamiAdditions+Retina.h"
#import "FBOrigamiAdditions+StructureIterator.h"
#import "FBOrigamiAdditions+TextFieldShortcuts.h"
#import "FBOrigamiAdditions+Tooltips.h"
#import "FBOrigamiAdditions+WindowManagement.h"
#import "FBOrigamiAdditions+WindowMods.h"
#import "FBOrigamiAdditions+Wireless.h"
#import "FBOLiveFilePatch.h"
#import "GRPHookMethod.h"
#import "NSMenu+FBAdditions.h"
#import "NSObject+AssociatedObjects.h"
#import "NSObject+FBAdditions.h"
#import "NSString+FBAdditions.h"
#import "QCPatch+FBAdditions.h"
#import "QCPatchView+FBAdditions.h"
#import "QCPort+FBAdditions.h"
#pragma clang diagnostic ignored "-Wincomplete-implementation"

#define ORIGAMI_APP_NAME            [[origamiBundle infoDictionary] objectForKey:@"CFBundleName"]
#define ORIGAMI_WEBSITE             @"http://origami.facebook.com/"
#define ORIGAMI_BUNDLE_IDENTIFIER   @"com.facebook.Origami"
#define ORIGAMI_ICON_FILE           @"Origami"
#define QC_DOWNLOAD_URL             @"https://origami.facebook.com/quartzcomposer/"

static FBOrigamiAdditions *sharedSingleton;
static SUUpdater *origamiUpdater;
static NSBundle *origamiBundle;
static NSString *kMinimumSupportedQCVersion = @"4.6";

@interface NSMenu (DumbXcode61Bullshit)
- (void)insertItem:(NSMenuItem *)newItem atIndex:(NSInteger)index;
@end

@interface FBOrigamiAdditions ()
- (void)original_applyFunctionOnInputPorts:(void *)arg1 context:(void *)arg2;
- (void)original_applyFunctionOnOutputPorts:(void *)arg1 context:(void *)arg2;
- (NSSize)original_sizeForNode:(QCPatch *)node;
- (NSArray *)pluginsLocatedInSubfolders;
- (void)original_delete:(id)fp8;
@end

@implementation FBOrigamiAdditions

+ (void)initialize
{
  static BOOL initialized = NO;
  if (!initialized && [[NSProcessInfo processInfo].processName isEqualToString:@"Quartz Composer"]) {
      initialized = YES;
      sharedSingleton = [[FBOrigamiAdditions alloc] init];
      origamiBundle = [NSBundle bundleWithIdentifier:ORIGAMI_BUNDLE_IDENTIFIER];
  }
}

+ (FBOrigamiAdditions *)sharedAdditions {
  return sharedSingleton;
}

+ (NSBundle *)origamiBundle {
  return origamiBundle;
}

- (void)initialSetup {
  [self checkQCVersion];
  [self registerDefaultPreferences];
  [self loadPluginsInSubfolders];
  [self setupWindowMods];
  [self setupRetina];
  [self setupLinearPortConnections];
  [self setupTextFieldShortcuts];
  [self setupPortNameDemangling];
  [self setupRenderInImageHacks];
  [self setupDimDisabledConsumers];
  [self setupDragAndDrop];
  [self setupKeyboardShortcuts];

  // Work around Mavericks bugs
  if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_8) {
    [self mavericksSwizzles];
  }
  
  // Use Helvetica on Logic and Math patches instead of Lucida Grande
  NSDictionary *circlePatchAttributes = @{ NSForegroundColorAttributeName : [NSColor whiteColor], NSFontAttributeName : [NSFont fontWithName:@"Helvetica-Bold" size:10.0] };
  GRPHookMethod(NSClassFromString(@"QCCirclePatchActor"), @selector(_portTextAttributesForNode:), ^(QCPatchActor *self, QCPatch *node) {
    return circlePatchAttributes;
  });
  
  // If you drop a cable over a macro patch, make a new port on that patch and connect it
  GRPHookMethod([GFGraphView class], @selector(trackConnection:fromPort:atPoint:), ^(GFGraphView *self, id event, QCPort *sourcePort, NSPoint point) {
     GRPCallOriginal(event,sourcePort,point);
    QCPatch *hoveredPatch = [[FBOrigamiAdditions sharedAdditions] patchUnderCursorInPatchView:(QCPatchView *)self];
    QCPort *hoveredPort = [[FBOrigamiAdditions sharedAdditions] portUnderCursorInPatchView:(QCPatchView *)self];
    
    if (hoveredPatch && !hoveredPort && hoveredPatch != sourcePort.node) {
      QCSplitter *splitter = (QCSplitter *)[QCPatch createPatchWithName:@"QCSplitter"];
      BOOL canAdd = [hoveredPatch canAddNode:splitter];
      
      if (canAdd) {
        [hoveredPatch addSubpatch:splitter];
        
        NSPoint position = [self _centerPoint];
        NSSize size = splitter.fb_actorSizeInKeyPatchView;
        position.x -= roundf(size.width / 2.0);
        position.y -= roundf(size.height / 2.0);
        splitter.userInfo[@"position"] = [NSValue valueWithPoint:position];
        
        [splitter setPortClass:[sourcePort baseClass]];
        
        NSString *portKey = [hoveredPatch uniqueProxyPortKeyFromName:sourcePort.fb_name];
        QCPort *publishedPort = [hoveredPatch createProxyPortWithOriginalPort:splitter.inputPorts[0] forKey:portKey];
        
        NSString *newName = [publishedPort editName:sourcePort.fb_name inView:self];
        
        splitter.userInfo[@"name"] = newName;
        publishedPort.userInfo[@"name"] = newName;
        
        [[self graph] createConnectionFromPort:sourcePort toPort:publishedPort];
      }
    }
   });
  
  // Keep connections around when you delete a patch
  [self fb_swizzleInstanceMethod:@selector(delete:) forClassName:@"GFGraphView"];
  
  if (!FBToolsIsInstalled()) {
    [self additionalSetupForNonEmployees];
  }
  
  [self setupOrigamiMenu];
  [self setupNewFileMenuItem];
  [self setupQuickTimeMenuItem];
  [self setupTooltipHiding];
  [self setupInlineValues];
  [self setupWindowManagementMenuItems];
  [self setupPatchMenu];
  [self setupStructureIteratorShortcuts];
  [self setupWireless];
  
  if ([self respondsToSelector:@selector(origamiDidLoad)]) {
    [self performSelector:@selector(origamiDidLoad)];
  }
  
  [self checkForInstallationIssues];
}

- (void)additionalSetupForNonEmployees {
  if (FBToolsIsInstalled()) {
    return;
  }
  
  // Setup the updater
  origamiUpdater = [SUUpdater updaterForBundle:origamiBundle];
  [origamiUpdater setDelegate:sharedSingleton];
}

#pragma mark Patch Deletion

// Keep connections around when you delete a patch

- (void)delete:(id)fp8 {
  GFGraphView *graphView = (GFGraphView *)self;
  NSArray *selectedNodes = ((QCPatch *)graphView.graph).selectedNodes;
  
  for (QCPatch *patch in selectedNodes) {
    if (patch.inputPorts.count > 0 && patch.outputPorts.count > 0) {
      NSArray *portConnectedToInput = ((QCPort *)patch.inputPorts[0]).fb_connectedPorts;
      NSArray *portsConnectedToOutput = ((QCPort *)patch.outputPorts[0]).fb_connectedPorts;
      
      if (portConnectedToInput.count > 0 && portsConnectedToOutput.count > 0)
        [[FBOrigamiAdditions sharedAdditions] transferValueOrConnectionsFromPort:patch.outputPorts[0] toPort:portConnectedToInput[0]];
    }
  }

  [self original_delete:fp8];
}

#pragma mark Quartz Composer Version Checking

- (NSString *)qcVersionNumber {
  NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
  NSString *versionNumber = [infoDict objectForKey:@"CFBundleShortVersionString"];
  return versionNumber;
}

- (void)checkQCVersion {
  NSString *versionNumber = [self qcVersionNumber];

  if (versionNumber.floatValue < (kMinimumSupportedQCVersion.floatValue - 0.01)) {
    NSString *title = NSLocalizedString(@"Update Quartz Composer", @"Please update Quartz Composer");
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Origami requires Quartz Composer %@ or greater. This version is %@. Please update to the latest version of Quartz Composer to use Origami.", @"Message explaning that users should update"),kMinimumSupportedQCVersion,versionNumber];
    NSString *defaultButton = NSLocalizedString(@"Download Update", @"Button label to download a new version of Quartz Composer.");
    NSString *otherButton = NSLocalizedString(@"Not Now", @"Button label to close the dialog");
    
    NSAlert *alert = [NSAlert alertWithMessageText:title defaultButton:defaultButton alternateButton:nil otherButton:otherButton informativeTextWithFormat:message,nil];
    alert.icon = [origamiBundle imageForResource:ORIGAMI_ICON_FILE];
    [alert beginSheetModalForWindow:nil modalDelegate:self didEndSelector:@selector(qcVersionAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
  }
}

- (void)qcVersionAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
  if (returnCode == NSAlertDefaultReturn) {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:QC_DOWNLOAD_URL]];
  }
}

#pragma mark Origami Menu Items

- (void)setupQuickTimeMenuItem {
  // Disable the broken Quicktime exporting functionality
  NSMenu *fileMenu = [[[NSApp mainMenu] itemWithTag:1] submenu];
  for (NSMenuItem *item in fileMenu.itemArray) {
    if ([item.title hasPrefix:@"Export"]) {
      item.target = self;
      item.action = @selector(exportToQuickTime:);
    }
  }
}

- (void)exportToQuickTime:(id)sender {
  NSString *title = NSLocalizedString(@"Export to QuickTime", @"Export to QuickTime");
  NSString *message = NSLocalizedString(@"Record your prototype with QuickTime X to export it as a movie. In QuickTime X, choose File > New Screen Recording and select the part of the screen where your prototype is running.", @"Message explaning that users should use QuickTime X to record");
  NSString *defaultButton = NSLocalizedString(@"OK", @"OK");
  
  NSAlert *alert = [NSAlert alertWithMessageText:title defaultButton:defaultButton alternateButton:nil otherButton:nil informativeTextWithFormat:message,nil];
  alert.icon = [origamiBundle imageForResource:ORIGAMI_ICON_FILE];
  [alert beginSheetModalForWindow:nil modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void)setupNewFileMenuItem {
  NSMenu *fileMenu = [[[NSApp mainMenu] itemWithTag:1] submenu];
  
  NSMenuItem *newFileItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"New Origami File", @"Menu item to create a new Origami template") action:@selector(newOrigamiFile:) keyEquivalent:@"n"];
  newFileItem.keyEquivalentModifierMask = NSAlternateKeyMask|NSCommandKeyMask;
  [(id)newFileItem setTarget:self];
  [fileMenu insertItem:newFileItem atIndex:0];
  
  NSMenuItem *importSketchItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Import Sketch File...", @"Menu item to import from Sketch and create a new file") action:@selector(importSketchFile:) keyEquivalent:@"o"];
  importSketchItem.keyEquivalentModifierMask = NSAlternateKeyMask|NSCommandKeyMask|NSControlKeyMask;
  [(id)importSketchItem setTarget:self];
  [fileMenu insertItem:importSketchItem atIndex:1];
  
  [fileMenu insertItem:[NSMenuItem separatorItem] atIndex:2];
}

- (void)setupOrigamiMenu {
  self.origamiMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:ORIGAMI_APP_NAME];
  NSMenuItem *origamiMenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ORIGAMI_APP_NAME action:NULL keyEquivalent:@""];
  NSImage *image = [[NSImage alloc] initByReferencingFile:[origamiBundle pathForImageResource:@"OrigamiMenubar-normal"]];
  image.template = YES;
  origamiMenuItem.image = image;
  [origamiMenuItem setSubmenu:self.origamiMenu];
  
  // Add the menu before the window menu (similar logic as KinemeCore so we can group with them)
  NSUInteger menuItemCount = [[NSApp mainMenu] itemArray].count;
  [[NSApp mainMenu] insertItem:origamiMenuItem atIndex:menuItemCount-2];
  
  [self.origamiMenu addItemWithTitle:NSLocalizedString(@"Examples", @"Menu item label to display examples")
                       keyEquivalent:@""
                              target:self
                              action:@selector(showExamples:)
                               state:NO];
  
  [self.origamiMenu addItemWithTitle:NSLocalizedString(@"Tutorials", @"Menu item label to display tutorials")
                       keyEquivalent:@""
                              target:self
                              action:@selector(showTutorials:)
                               state:NO];
  
  [self.origamiMenu addItemWithTitle:NSLocalizedString(@"Documentation", @"Menu item label to display documentation")
                       keyEquivalent:@""
                              target:self
                              action:@selector(showDocumentation:)
                               state:NO];

  [self.origamiMenu addItemWithTitle:NSLocalizedString(@"Community", @"Menu item label to display the community group")
                       keyEquivalent:@""
                              target:self
                              action:@selector(showCommunity:)
                               state:NO];
  
  [self.origamiMenu addItem:[NSMenuItem separatorItem]];
  
  [self setupCodeExportMenuItems];
  
  [self.origamiMenu addItem:[NSMenuItem separatorItem]];
  
  [self.origamiMenu addItemWithTitle:NSLocalizedString(@"About Origami", @"Menu item label to display application information")
                       keyEquivalent:@""
                              target:self
                              action:@selector(aboutOrigami:)
                               state:NO];
  
  if (!FBToolsIsInstalled() && origamiUpdater) {
    [self.origamiMenu addItemWithTitle:NSLocalizedString(@"Check for Updates...", @"Menu item label to check for application updates")
                         keyEquivalent:@""
                                target:self
                                action:@selector(checkForUpdates:)
                                 state:NO];
  }

  [self.origamiMenu addItem:[NSMenuItem separatorItem]];
  
  self.retinaSupportMenuItem =
    [self.origamiMenu addItemWithTitle:NSLocalizedString(@"Retina Support", @"Menu item for toggling retina display support")
                         keyEquivalent:@""
                                target:self
                                action:@selector(toggleOrigamiPreferenceMenuItem:)
                                 state:FBOrigamiAdditions.isRetinaSupportEnabled];
  
  self.linearPortConnectionsMenuItem =
    [self.origamiMenu addItemWithTitle:NSLocalizedString(@"Linear Port Connections", @"Menu item label to toggle linear port connections feature")
                         keyEquivalent:@""
                                target:self
                                action:@selector(toggleOrigamiPreferenceMenuItem:)
                                 state:FBOrigamiAdditions.isLinearPortConnectionsEnabled];
}

- (IBAction)aboutOrigami:(id)sender {
  NSString *version = [origamiBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
  
  const unichar copyrightSymbolCharacter = 0x00A9;
  NSString *copyrightSymbol = [NSString stringWithCharacters:&copyrightSymbolCharacter length:1];
  NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"%@ %@", @"Application name and version number"), ORIGAMI_APP_NAME, version] defaultButton:NSLocalizedString(@"OK", @"OK") alternateButton:nil otherButton:NSLocalizedString(@"Visit Website", @"Button label to visit the Origami website") informativeTextWithFormat:NSLocalizedString(@"%@ 2013-2016 Facebook, Inc.", @"Summarized copyright information"), copyrightSymbol];
  alert.icon = [origamiBundle imageForResource:ORIGAMI_ICON_FILE];
  [alert beginSheetModalForWindow:nil modalDelegate:self didEndSelector:@selector(aboutOrigamiAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)aboutOrigamiAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
  if (returnCode == NSAlertOtherReturn) {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ORIGAMI_WEBSITE]];
  }
}

- (void)showExamples:(id)sender {
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://facebook.github.io/origami/examples/"]];
}

- (void)showTutorials:(id)sender {
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://facebook.github.io/origami/tutorials/"]];
}

- (void)showDocumentation:(id)sender {
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://facebook.github.io/origami/documentation/"]];
}

- (void)showCommunity:(id)sender {
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.facebook.com/groups/origami.community/"]];
}

- (IBAction)checkForUpdates:(id)sender {
  [origamiUpdater resetUpdateCycle];
  [origamiUpdater checkForUpdates:self];
}

- (void)toggleOrigamiPreferenceMenuItem:(NSMenuItem *)menuItem {
  menuItem.state = !menuItem.state;
  if (menuItem == self.retinaSupportMenuItem) {
    [FBOrigamiAdditions toggleRetinaSupportEnabled];
  } else if (menuItem == self.linearPortConnectionsMenuItem) {
    [FBOrigamiAdditions toggleLinearPortConnectionsEnabled];
  }
}

#pragma mark Port Name De-mangling
// Fix the port name mangling bug introduced in 10.7 / 10.8. There's a bug in the QC port name localization code that replaces the correct name
// in the -[GFPort userInfo] dictionary with the port's key. For example, a port named "0-1 Value" will be renamed to something like "01_Value".
// This hack stops the localization function __LocalizePortInfo from being called when patches are loaded.
//
// What's happening:
// -[QCNodeManager _patchFromComposition] calls _QCPatchFromCompositionWithOptions(comp,options,nil) with an options dictionary containing
// @"localizeInterface" = YES (hard coded). If this is set to YES, it calls -[QCNode applyFunctionOnInputPorts:context:] with the function
// _LocalizePortInfo() and a nil context. The _LocalizePortInfo() function calls _GetLocalizedString() and sets that string as the @"name"
// in the port's userInfo dictionary. This hack stops _LocalizePortInfo() from being called from a call stack containing the
// _QCPatchFromCompositionWithOptions() function.
//
// Update: Looking for the _patchFromComposition: method instead of _QCPatchFromCompositionWithOptions() to support deployment builds which
// seem to have functions omitted in the call stack log.

- (void)setupPortNameDemangling {
  [self fb_swizzleInstanceMethod:@selector(applyFunctionOnInputPorts:context:) forClassName:@"GFNode"];
  [self fb_swizzleInstanceMethod:@selector(applyFunctionOnOutputPorts:context:) forClassName:@"GFNode"];
}

- (void)applyFunctionOnInputPorts:(void *)arg1 context:(void *)arg2 {
  if (![[FBOrigamiAdditions sharedAdditions] functionIsLocalizePortInfo:arg1])
      [self original_applyFunctionOnInputPorts:arg1 context:arg2];
}

- (void)applyFunctionOnOutputPorts:(void *)arg1 context:(void *)arg2 {
  if (![[FBOrigamiAdditions sharedAdditions] functionIsLocalizePortInfo:arg1])
      [self original_applyFunctionOnOutputPorts:arg1 context:arg2];
}

- (BOOL)functionIsLocalizePortInfo:(void *)function {
  if (!self.localizePointer) {
    NSArray *callStack = [NSThread callStackSymbols];

    if (callStack.count >= 4) {
      if ([callStack[3] fb_containsString:@"_patchFromComposition:"] || [callStack[1] fb_containsString:@"_patchFromComposition:"]) { // Index 3 in development builds, index 1 in deployment
        self.localizePointer = function;
      }
    }
  }
  
  return function == self.localizePointer;
}

#pragma mark Installation Issue Troubleshooting

- (void)checkForInstallationIssues {
//  NSString *userLibraryPath = [@"~/Library/Graphics/Quartz Composer Patches/Origami.plugin" stringByExpandingTildeInPath];
  NSString *localLibraryPath = @"/Library/Graphics/Quartz Composer Patches/Origami.plugin";
  NSString *systemLibraryPath = @"/System/Library/Graphics/Quartz Composer Patches/Origami.plugin";
  NSString *sharedLibraryPath = @"/Users/Shared/Library/Graphics/Quartz Composer Patches/Origami.plugin";

//  BOOL existsInUserLibrary = [[NSFileManager defaultManager] fileExistsAtPath:userLibraryPath];
  BOOL existsInLocalLibrary = [[NSFileManager defaultManager] fileExistsAtPath:localLibraryPath];
  BOOL existsInSystemLibrary = [[NSFileManager defaultManager] fileExistsAtPath:systemLibraryPath];
  BOOL existsInSharedLibrary = [[NSFileManager defaultManager] fileExistsAtPath:sharedLibraryPath];
  
  if (existsInLocalLibrary)
    [self displayWrongInstallPathAlert:@"local library"];
  else if (existsInSystemLibrary)
    [self displayWrongInstallPathAlert:@"system library"];
  else if (existsInSharedLibrary)
    [self displayWrongInstallPathAlert:@"shared library"];
}

- (void)displayWrongInstallPathAlert:(NSString *)pathDescription {
  NSString *title = NSLocalizedString(@"Origami Installation Issue", @"Origami Installation Issue");
  NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Origami has been installed to the wrong location (%@). Please uninstall Origami using the uninstaller and reinstall it from origami.facebook.com.", @"Message explaning that users should reinstall"),pathDescription];
  NSString *defaultButton = NSLocalizedString(@"Download Uninstaller", @"Button label to download the uninstaller.");
  NSString *otherButton = NSLocalizedString(@"Not Now", @"Button label to close the dialog");
  
  NSAlert *alert = [NSAlert alertWithMessageText:title defaultButton:defaultButton alternateButton:nil otherButton:otherButton informativeTextWithFormat:message,nil];
  alert.icon = [origamiBundle imageForResource:ORIGAMI_ICON_FILE];
  [alert beginSheetModalForWindow:nil modalDelegate:self didEndSelector:@selector(downloadUninstallerAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)downloadUninstallerAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
  if (returnCode == NSAlertDefaultReturn) {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.dropbox.com/s/v8y7k4dxxazk3i4/Origami%20Uninstaller.zip?dl=0"]];
  }
}

#pragma mark Transfer Port Values
// TODO: Find a better place for this

- (void)transferValueOrConnectionsFromPort:(QCPort *)oldPort toPort:(QCPort *)newPort {
  QCPatch *parentPatch = ((QCPatch *)oldPort.node).parentPatch;
  BOOL patchesAreSiblings = ((QCPatch *)newPort.node).parentPatch == parentPatch;
  if (!(oldPort && oldPort.direction == newPort.direction && patchesAreSiblings))
    return;
  
  NSArray *connectedPorts = [oldPort fb_connectedPorts];
  if (connectedPorts.count == 0)
    return;
  
  if (oldPort.fb_isInputPort) {
    if (oldPort.baseClass != [QCInteractionPort class] && newPort.baseClass != [QCInteractionPort class] && oldPort.baseClass != [QCVirtualPort class] && newPort.baseClass != [QCVirtualPort class]) {
      [newPort setValue:[oldPort value]];
    }
    
    [parentPatch createConnectionFromPort:connectedPorts[0] toPort:newPort];
  } else {
    for (QCPort *chainedPort in connectedPorts) {
      [parentPatch createConnectionFromPort:newPort toPort:chainedPort];
    }
  }
}

#pragma mark Inserting Patches
// TODO: Find a better place for this

- (void)insertPatch:(QCPatch *)newPatch inPatchView:(QCPatchView *)patchView {
  [self insertPatch:newPatch inPatchView:patchView inputPortKey:nil outputPortKey:nil];
}

// This method expects either an inputPortKey or an outputPortKey, but not both. Probably bad API.
- (void)insertPatch:(QCPatch *)newPatch inPatchView:(QCPatchView *)patchView inputPortKey:(NSString *)inputPortKey outputPortKey:(NSString *)outputPortKey {
  if (!newPatch)
    return;
  
  QCPort *port = self.hoveredPort;
  
  QCPort *newPatchInPort = inputPortKey ? [newPatch portForKey:inputPortKey] : newPatch.inputPorts[0];
  QCPort *newPatchOutPort = outputPortKey ? [newPatch portForKey:outputPortKey] : newPatch.outputPorts[0];
  
  NSPoint position = NSZeroPoint;
  
  if (port) {
    QCPort *newPort = port.fb_isInputPort ? newPatchOutPort : newPatchInPort;
    position = [patchView fb_positionForPatchWithPort:newPort alignedToPort:port];
  } else {
    position = [self mousePositionInView:patchView];
    CGSize actorSize = newPatch.fb_actorSizeInKeyPatchView;
    position.x -= roundf(actorSize.width / 2);
    position.y -= roundf(actorSize.height / 2);
  }
  
  [patchView fb_addPatch:newPatch];
  newPatch.userInfo[@"position"] = [NSValue valueWithPoint:position];
  
  if (port == nil)
    return;
  
  BOOL shouldRestoreConnections = ((port.fb_isInputPort && newPatch.inputPorts.count > 0) || (!port.fb_isInputPort && newPatch.outputPorts.count > 0)) && !([NSEvent modifierFlags] & NSAlternateKeyMask);
  NSArray *connectedPorts = shouldRestoreConnections ? [port fb_connectedPorts] : nil;
  
  if (port.fb_isInputPort) {
    if (port.baseClass != [QCInteractionPort class] && port.baseClass != [QCVirtualPort class]) {
      [newPatchInPort setValue:[port value]];
    }
    
    [[patchView graph] createConnectionFromPort:newPatchOutPort toPort:port];
    
    if (connectedPorts.count > 0) {
      [[patchView graph] createConnectionFromPort:connectedPorts.lastObject toPort:newPatchInPort];
    }
  } else {
    [[patchView graph] createConnectionFromPort:port toPort:newPatchInPort];
    
    for (GFPort *chainedPort in connectedPorts) {
      [[patchView graph] createConnectionFromPort:newPatchOutPort toPort:chainedPort];
    }
  }
}

#pragma mark Utilities
// TODO: Find a better place for this

- (QCPatch *)patchUnderCursorInPatchView:(QCPatchView *)patchView {
  if (!patchView) {
    patchView = [self patchView];
  }
  
  NSPoint mousePosition = [[FBOrigamiAdditions sharedAdditions] mousePositionInView:patchView];
  QCPatch *node = [patchView _nodeAtPosition:mousePosition outBounds:nil];
  
  return node;
}

- (QCPort *)portUnderCursorInPatchView:(QCPatchView *)patchView {
  if (!patchView) {
    patchView = [self patchView];
  }
  
  QCPatch *node = [self patchUnderCursorInPatchView:patchView];
  
  if (!node)
    return nil;
  
  NSPoint mousePosition = [self mousePositionInView:patchView];
  NSRect bounds = [patchView boundsForNode:node];
  QCPatchActor *actor = [patchView nodeActorForNode:node];
  QCPort *port = [actor portForPoint:mousePosition inNode:node bounds:bounds];
  
  return port;
}

- (NSPoint)mousePositionInView:(NSView *)view {
  NSPoint mousePosInScreen = [NSEvent mouseLocation];
  NSPoint mousePosInWindow = [[view window] convertScreenToBase:mousePosInScreen];
  NSPoint mousePosInView = [view convertPoint:mousePosInWindow fromView:nil];
  
  return mousePosInView;
}

- (id)editorController {
  NSDocumentController *docController = [[NSApplication sharedApplication] performSelector:@selector(sharedDocumentController)];
  NSDocument *currentDocument = [docController currentDocument];
  id editorController = [currentDocument performSelector:@selector(editorController)];
  return editorController;
}

- (id)viewerController {
  NSDocumentController *docController = [[NSApplication sharedApplication] performSelector:@selector(sharedDocumentController)];
  NSDocument *currentDocument = [docController currentDocument];
  id viewerController = [currentDocument performSelector:@selector(viewerController)];
  return viewerController;
}

- (QCPatchView *)patchView {
  QCPatchEditorView *editingView = [[self editorController] performSelector:@selector(editingView)];
  return [editingView graphView];
}

- (QCPatch *)currentPatch {
  return [[self patchView] graph];
}

- (NSArray *)selectedPatches {
  return [[self currentPatch] selectedNodes];
}

@end
