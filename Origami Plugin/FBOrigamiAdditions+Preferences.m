/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiAdditions+Preferences.h"

static NSString *const kRetinaDisabledPreferenceKey = @"FBOrigamiRetinaDisabled";
static NSString *const kLinearPortConnectionsPreferenceKey = @"FBOrigamiLinearPortConnections";

static NSUserDefaults *OrigamiDefaults;

@implementation FBOrigamiAdditions (Preferences)

- (void)registerDefaultPreferences {
  OrigamiDefaults = [NSUserDefaults standardUserDefaults];
  [OrigamiDefaults registerDefaults:
    @{
      kRetinaDisabledPreferenceKey: @(NO),
      kLinearPortConnectionsPreferenceKey: @(YES)
    }
  ];
}

+ (BOOL)isRetinaSupportEnabled {
  return (![OrigamiDefaults boolForKey:kRetinaDisabledPreferenceKey]);
}

+ (void)toggleRetinaSupportEnabled {
  [OrigamiDefaults setBool:[FBOrigamiAdditions isRetinaSupportEnabled] forKey:kRetinaDisabledPreferenceKey];
}

+ (BOOL)isLinearPortConnectionsEnabled {
  return [OrigamiDefaults boolForKey:kLinearPortConnectionsPreferenceKey];
}

+ (void)toggleLinearPortConnectionsEnabled {
  [OrigamiDefaults setBool:(![FBOrigamiAdditions isLinearPortConnectionsEnabled]) forKey:kLinearPortConnectionsPreferenceKey];
}

@end
