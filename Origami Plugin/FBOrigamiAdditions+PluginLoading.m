/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOrigamiAdditions+PluginLoading.h"

@implementation FBOrigamiAdditions (PluginLoading)

- (void)loadPluginsInSubfolders {
  GFNodeManager *nodeManager = [GFNodeManager managerForNodeNamespace:@"com.apple.QuartzComposer"];
  NSArray *pluginsToLoad = [self pluginsLocatedInSubfolders];
  
  for (NSString *pluginToLoad in pluginsToLoad) {
    [nodeManager loadPlugInAtPath:pluginToLoad];
  }
}

- (bool)_shouldLoadPluginFile:(id)object ignoringTopLevelFiles:(bool)ignoringTopLevel{
  NSArray *pathComponents = [object pathComponents];
  // Skip top-level patches because those are already loaded
  if (ignoringTopLevel && [pathComponents count] == 1) {
    return NO;
  }

  // Skip plugins that aren't QTZ or plugin files
  if (!([[object pathExtension] isEqualToString:@"qtz"] || [[object pathExtension] isEqualToString:@"plugin"])) {
    return NO;
  }

  // Skip files nested in bundles and plugins
  NSArray *pathComponentsExceptLast = [pathComponents subarrayWithRange:NSMakeRange(0, [pathComponents count] - 1)];
  for (NSString *pathComponentAlongTheWay in pathComponentsExceptLast) {
    if ([[pathComponentAlongTheWay pathExtension] isEqualToString:@"bundle"] || [[pathComponentAlongTheWay pathExtension] isEqualToString:@"plugin"]) {
      return NO;
    }
  }

  return YES;
}

- (NSArray *)pluginsLocatedInSubfolders {
  NSArray *pluginsFolders = @[
                              @"/System/Library/Graphics/Quartz Composer Patches",
                              @"/Library/Graphics/Quartz Composer Patches",
                              [@"~/Library/Graphics/Quartz Composer Patches" stringByStandardizingPath]
                              ];
  
  NSMutableArray *pluginsToLoad = [NSMutableArray array];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSError *error;
  
  /**
   First, identify any symbolic links at the root level of the plugins folders,
   and then load any of the patches found there.
   */
  for (NSString *pluginsFolder in pluginsFolders) {
    NSArray *rootFolderContents = [fileManager contentsOfDirectoryAtPath:pluginsFolder error:&error];
    for (NSString *possibleSymlink in rootFolderContents){
      NSString *dir = [fileManager destinationOfSymbolicLinkAtPath:[pluginsFolder stringByAppendingPathComponent:possibleSymlink] error:nil];
      if (dir){
        NSArray *folderContents = [fileManager contentsOfDirectoryAtPath:dir error:&error];
        NSArray *validPlugins = [folderContents filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
          return [self _shouldLoadPluginFile:object ignoringTopLevelFiles:NO];
        }]];
        for (NSString *validPlugin in validPlugins) {
          [pluginsToLoad addObject:[dir stringByAppendingPathComponent:validPlugin]];
        }
      }
    }
  }

  /**
   Then recursively load QTZ files.
   */
  for (NSString *pluginsFolder in pluginsFolders) {
    NSArray *folderContents = [fileManager subpathsOfDirectoryAtPath:pluginsFolder error:&error];
    NSArray *validPlugins = [folderContents filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
      return [self _shouldLoadPluginFile:object ignoringTopLevelFiles:YES];
    }]];
    
    for (NSString *validPlugin in validPlugins) {
      [pluginsToLoad addObject:[pluginsFolder stringByAppendingPathComponent:validPlugin]];
    }
  }
  
  return pluginsToLoad;
}

@end
