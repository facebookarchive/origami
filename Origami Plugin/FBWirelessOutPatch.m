/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBWirelessOutPatch.h"
#import "FBWirelessOutPatchUI.h"
#import "FBWirelessController.h"

@implementation FBWirelessOutPatch

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8
{
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8
{
	return kQCPatchExecutionModeProvider;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)identifier
{
  return kQCPatchTimeModeNone;
}

- (id)initWithIdentifier:(id)fp8
{
	if (self = [super initWithIdentifier:fp8]) {
    [[self userInfo] setObject:@"Wireless Receiver" forKey:@"name"];
    
    [self controller];
  }
  
	return self;
}

- (FBWirelessController *)controller {
  if (_controller == nil) {
    FBWirelessController *c = [FBWirelessController controllerForPatch:self];
    if (c) {
      self.controller = c;
      
      if (!_selectedKey && self.controller.keyedData.count > 0) {
        if ([self.controller.keyedData.allKeys containsObject:self.controller.lastCreatedKey]) {
          self.selectedKey = self.controller.lastCreatedKey;
        } else {
          self.selectedKey = self.controller.keyedData.allKeys.lastObject;
        }
      }
    }
  }
  
  return _controller;
}

+ (Class)inspectorClassWithIdentifier:(id)fp8
{
	return [FBWirelessOutPatchUI class];
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments
{
  if (self.controller == nil) {
    NSLog(@"Wireless receiver can't find controller");
  }
  
  NSMutableDictionary *dict = _controller.keyedData;
  
  if (dict && self.selectedKey) {
    [outputValue setRawValue:dict[self.selectedKey]];
  }

	return YES;
}

- (id)nodeActorForView:(NSView *)view
{ 
  Class QCMiniPatchActor = objc_getClass("QCMiniPatchActor");
  id actor = [QCMiniPatchActor sharedActor];

  return actor;
}

- (void)setSelectedKey:(NSString *)key {
  _selectedKey = [key copy];
  
  if (key && key.length > 0)
    [[self userInfo] setObject:key forKey:@"name"];
}

- (NSDictionary *)state
{
	NSMutableDictionary *stateDict = [NSMutableDictionary dictionary];
	[stateDict addEntriesFromDictionary:[super state]];
  
  if (_selectedKey)
    [stateDict setObject:_selectedKey forKey:@"FBWirelessOutSelectedKey"];
  
  return stateDict;
}

- (BOOL)setState:(NSDictionary *)state
{
  self.selectedKey = [state objectForKey:@"FBWirelessOutSelectedKey"];
  
	return [super setState:state];
}

@end
