/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOLiveFilePatch.h"
#import "FBOLiveFilePatchUI.h"
#import "CDEvents.h"
#import "NSString+FBAdditions.h"
#import "QCPatch+FBAdditions.h"

@interface FBOLiveFilePatch ()
@property (retain, nonatomic) CDEvents *events;
@property (assign) BOOL updatedViaSettings;
@end

@implementation FBOLiveFilePatch

#pragma mark - QCPatch Characteristics

/**
 This is nessecary for QC to archive the state of this patch. Keys listed here
 in addition to `userInfo` and other built-in state information will be persisted,
 and reset by `setState:` when patches are restored.
 */
+ (NSArray*)stateKeysWithIdentifier:(id)identifier { return @[@"filePath",@"cachedImage",@"useAbsolutePath",@"disableEmbedding"]; }

+ (BOOL)allowsSubpatchesWithIdentifier:(id)identifier { return NO; }
+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)identifier {return kQCPatchExecutionModeProvider;}
+ (Class)inspectorClassWithIdentifier:(id)identifier {return [FBOLiveFilePatchUI class];}
+ (QCPatchTimeMode)timeModeWithIdentifier:(id)identifier {return kQCPatchTimeModeIdle;}

#pragma mark - Patch Behavior

-(id)initWithIdentifier:(id)identifier {
  if (self = [super initWithIdentifier:identifier]) {

  }
  
	return self;
}

- (void)setPathString:(NSString *)path {
  inputPath.stringValue = path;
}

-(void)setFilePath:(NSString *)filePath{
  NSURL *url;
  NSURL *compURL = [[self fb_document] fileURL];

  filePath = [filePath stringByExpandingTildeInPath];
  
  // Absolute Path & the file is saved
  if ([filePath hasPrefix:@"/"] && compURL && ![self boolForStateKey:@"useAbsolutePath"]) {
    NSString *docPath = [[[[self fb_document] fileURL] path] stringByDeletingLastPathComponent];
    filePath = [filePath relativePathFromBaseDirPath:docPath];
    url = [[compURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:filePath];

  // Absolute Path and the file isn't saved.
  } else if ([filePath hasPrefix:@"/"]){
    url = [NSURL fileURLWithPath:filePath];

  // Relative Path
  } else if (filePath && compURL){
    url = [[[compURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:filePath] URLByStandardizingPath];
  } else {
//    NSLog(@"Unable to connect file at path: @%", filePath);
  }

//  NSLog(@"filePath: %@", filePath);
//  NSLog(@"compURL: %@", compURL);
//  NSLog(@"url: %@", url);
  if (self.updatedViaSettings){
    inputPath.stringValue = filePath;
  }
  [self setOutputImageWithURL:url];
  _filePath = filePath;
}

- (void)setDisableEmbedding:(BOOL)disableEmbedding {
  if (disableEmbedding){
    [self setValue:nil forStateKey:@"cachedImage"];
  }
  _disableEmbedding = disableEmbedding;
}

-(void)setOutputImageWithURL:(NSURL *)url {
  if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]]){
    self.fileFound = YES;
    [self resetImageFromURL:url];
    self.events = [[CDEvents alloc] initWithURLs:@[url] block:^(CDEvents *watcher, CDEvent *event) {
      [self resetImageFromURL:url];
    }];
  } else {
    self.fileFound = NO;
  }
//  NSLog(@"%@",self.fileFound ? @"File Connected" : @"File Not Found");
}

- (void)resetImageFromURL:(NSURL *)url {
  QCImage *image = [[QCImage alloc] initWithURL:url options:nil];
  if (self.disableEmbedding){
    [self setValue:nil forStateKey:@"cachedImage"];
    [outputImage setImageValue:image];
  } else {
    [self resetCacheAndDisplayImage:image atURL:url];
  }
}

- (void)resetCacheAndDisplayImage:(QCImage *)image atURL:(NSURL *)url {
  [self setValue:image forStateKey:@"cachedImage"];

  // Cache an NSImage to be rendered by FBPatchView (inline values)
  NSImage *nsImage = [[NSImage alloc] initWithContentsOfURL:url];
  self.cachedNSImage = nsImage;

  [self _showOutputImageFromCache];
}

- (void)_showOutputImageFromCache {
  if ([self valueForStateKey:@"cachedImage"] != nil){
     [outputImage setImageValue:[self valueForStateKey:@"cachedImage"]];
  }
}

/**
 Sets the output port with the index of the *last* input port that changed
 and is currently high.
 */
- (BOOL)execute:(QCOpenGLContext *)context
           time:(double)time
      arguments:(NSDictionary *)arguments
{

  if ([inputPath wasUpdated] && !self.updatedViaSettings){
    [self _showOutputImageFromCache];
    [self setFilePath:[inputPath stringValue]];
  }
  if (self.updatedViaSettings){
    self.updatedViaSettings = false;
  }
  return YES;
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if ([keyPath isEqualToString:@"filePath"]){
    self.updatedViaSettings = YES;
    [self setValue:[object valueForKey:keyPath] forStateKey:@"filePath"];
  } else if ([keyPath isEqualToString:@"useAbsolutePath"]){
    [self setBool:[[object valueForKey:keyPath] boolValue] forStateKey:@"useAbsolutePath"];
  } else if ([keyPath isEqualToString:@"disableEmbedding"]){
    [self setBool:[[object valueForKey:@"disableEmbedding"] boolValue] forStateKey:@"disableEmbedding"];
  }
}

@end
