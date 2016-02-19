/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "BWExceptionHandlerProvider.h"

#import <FBExceptionHandler/FBBreakpadExceptionHandler.h>

static NSString *kBreakpadURL = @"https://www.facebook.com/mobile/ios_breakpad_crash_logs/";

@implementation BWExceptionHandlerProvider

+ (FBBreakpadExceptionHandler *)provideConfiguredExceptionHandler {
  NSString *buildRevision = BW_TO_UNICODE_STRING(FB_BUILD_REVISION);
  NSString *bundleID = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleIdentifierKey];

  NSString *device;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    device = @"iPad";
  } else {
    device = @"iPhone";
  }

  NSString *appVersion = [BWExceptionHandlerProvider appVersionForBundle:[NSBundle mainBundle]];
  NSString *buildNumber = [BWExceptionHandlerProvider buildVersionForBundle:[NSBundle mainBundle]];
  NSString *iosVersion = [[UIDevice currentDevice] systemVersion];
  NSString *model = [[UIDevice currentDevice] model];
  NSDictionary *exceptionParams = @{@"Device":device,
                                    @"app_version":appVersion,
                                    @"build_number":buildNumber,
                                    @"ios_version":iosVersion,
                                    @"model":model,
                                    @"bundle_id":bundleID,
                                    @"session_id":[[NSUUID UUID] UUIDString]};

  FBBreakpadExceptionHandler *breakpadExceptionHandler =
    [[FBBreakpadExceptionHandler alloc] initWithUrl:kBreakpadURL
                                    exceptionParams:exceptionParams
                                            product:nil
                                      buildRevision:buildRevision];

  return breakpadExceptionHandler;
}

+ (NSString *)appVersionForBundle:(NSBundle *)bundle {
  NSString *appVersion;

  // Try loading the new-style app versions
  appVersion = [bundle objectForInfoDictionaryKey:@"FBAppVersion"];

  // Fallback to old-style app versions
  if (!appVersion || ![appVersion length]) {
    appVersion = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
  }

  return appVersion;
}

+ (NSString *)buildVersionForBundle:(NSBundle *)bundle {
  return [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
}

@end
