/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiPrincipal.h"
#import "FBOrigamiAdditions.h"
#import "BWDeviceInfoReceiver.h"

#import "FBOInteractionPatch.h"
#import "FBOLayerGroup.h"
#import "FBOLiveFilePatch.h"
#import "FBOMultiSwitchPatch.h"
#import "FBSafariTheme.h"
#import "FBSafariThemeButtons.h"
#import "FBHexToRGB.h"
#import "FBRGBToHex.h"
#import "FBCursorPatch.h"
#import "FBOProgressPatch.h"
#import "POPBouncyPatch.h"
#import "POPDecayPatch.h"
#import "POPConverterPatch.h"
#import "FBOMouseScrollPatch.h"
#import "FBODelayPatch.h"
#import "FBDragAndDropPatch.h"
#import "FBDeviceInfoPatch.h"
#import "FBDeviceRendererPatch.h"
#import "FBDeviceVibratePatch.h"
#import "FB3DOrientationPatch.h"
#import "FBOStructureCreatorPatch.h"
#import "FBOStructureCombinePatch.h"
#import "FBViewerDimensionsPatch.h"
#import "FBWirelessInPatch.h"
#import "FBWirelessOutPatch.h"
#import "FBStopWatchPatch.h"
#import "FBLastValue.h"
#import "DHJSONImporterPatch.h"
#import "DHAppleScriptPatch.h"
#import "DHImageAtURLPatch.h"
#import "DHRestRequestPatch.h"
#import "FBFileUpdated.h"
#import "FBDescriptionPatch.h"
#import "FBStructureShuffle.h"
#import "FBLogToConsole.h"
#import "FBFPS.h"
#import "DHImageWithFormattedStrings.h"
#import "DHStringFormatterPatch.h"
#import "DHStringAtURLPatch.h"
#import "DHSoundPlayerProPatch.h"
#import "DHStructureAllKeysPatch.h"
#import "DHStructureAllValuesPatch.h"
#import "DHStructureMultiplePathMembersPatch.h"
#import "DHStructurePathMemberPatch.h"

@implementation FBOrigamiPrincipal

+ (void)registerNodesWithManager:(QCNodeManager*)manager {
  KIRegisterPatch(FBOInteractionPatch);
  KIRegisterPatch(FBOLayerGroup);
  KIRegisterPatch(FBOLiveFilePatch);
  KIRegisterPatch(FBOMultiSwitchPatch);
  KIRegisterPatch(FBSafariTheme);
  KIRegisterPatch(FBSafariThemeButtons);
  KIRegisterPatch(FBHexToRGB);
  KIRegisterPatch(FBRGBToHex);
  KIRegisterPatch(FBCursorPatch);
  KIRegisterPatch(FBOProgressPatch);
  KIRegisterPatch(POPBouncyPatch);
  KIRegisterPatch(POPDecayPatch);
  KIRegisterPatch(POPConverterPatch);
  KIRegisterPatch(FBOMouseScrollPatch);
  KIRegisterPatch(FBODelayPatch);
  KIRegisterPatch(FBDragAndDropPatch);
  KIRegisterPatch(FBDeviceInfoPatch);
  KIRegisterPatch(FBDeviceRendererPatch);
  KIRegisterPatch(FBDeviceVibratePatch);
  KIRegisterPatch(FB3DOrientationPatch);
  KIRegisterPatch(FBOStructureCreatorPatch);
  KIRegisterPatch(FBOStructureCombinePatch);
  KIRegisterPatch(FBViewerDimensionsPatch);
  KIRegisterPatch(FBWirelessInPatch);
  KIRegisterPatch(FBWirelessOutPatch);
  KIRegisterPatch(FBStopWatchPatch);
  KIRegisterPatch(FBLastValue);
  KIRegisterPatch(DHJSONImporterPatch);
  KIRegisterPatch(DHAppleScriptPatch);
  KIRegisterPatch(DHImageAtURLPatch);
  KIRegisterPatch(DHRESTRequestPatch);
  KIRegisterPatch(FBFileUpdated);
  KIRegisterPatch(FBDescriptionPatch);
  KIRegisterPatch(FBStructureShuffle);
  KIRegisterPatch(FBLogToConsole);
  KIRegisterPatch(FBFPS);
  KIRegisterPatch(DHImageWithFormattedStrings);
  KIRegisterPatch(DHStringFormatterPatch);
  KIRegisterPatch(DHStringAtURLPatch);
  KIRegisterPatch(DHSoundPlayerProPatch);
  KIRegisterPatch(DHStructureAllKeysPatch);
  KIRegisterPatch(DHStructureAllValuesPatch);
  KIRegisterPatch(DHStructureMultiplePathMembersPatch);
  KIRegisterPatch(DHStructurePathMemberPatch);

  [[FBOrigamiAdditions sharedAdditions] initialSetup];
  [[BWDeviceInfoReceiver sharedReceiver] initialSetup];
}

@end
