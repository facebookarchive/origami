/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

// An anonymous count of the amount of people who use Origami every day.

#import "FBOrigamiAdditions+Stats.h"

#define ORIGAMI_STATS_ENDPOINT      @"https://origami-stats.herokuapp.com/track/origami"
#define ORIGAMI_STATS_API_KEY       @"nveJ23MnX/1xo+ZcVyVBAOv0pqq2x+FJq5BzFaN3gmY="
#define ORIGAMI_IID_KEY             @"OrigamiIID"

@implementation FBOrigamiAdditions (Stats)

- (void)origamiDidLoad {
  [self trackEvent:@"dau"];
}

- (void)trackEvent:(NSString *)eventName {
  NSString *ep = [ORIGAMI_STATS_ENDPOINT stringByAppendingPathComponent:eventName];
  NSURL *url = [NSURL URLWithString:ep];
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  
  request.HTTPMethod = @"POST";
  NSDictionary *data = @{ @"iid": [self installationID],
                          @"os_version": [[NSProcessInfo processInfo] operatingSystemVersionString],
                          @"qc_version": [self qcVersionNumber],
                          @"origami_version": [[FBOrigamiAdditions origamiBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]
                          };
  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
  if (jsonData){
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:ORIGAMI_STATS_API_KEY forHTTPHeaderField:@"X-OGS-API-KEY"];
    
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[jsonData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: jsonData];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:nil];
  }
}

- (NSString *)installationID {
  NSString *iid = [[NSUserDefaults standardUserDefaults] objectForKey:ORIGAMI_IID_KEY];
  if (!iid) {
    iid = [[NSUUID UUID] UUIDString];
    [[NSUserDefaults standardUserDefaults] setObject:iid forKey:ORIGAMI_IID_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
  return iid;
}

@end
