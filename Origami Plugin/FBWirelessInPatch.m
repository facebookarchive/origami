/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBWirelessInPatch.h"
#import "FBWirelessInPatchUI.h"

static NSString *kInitialName = @"\"Name\"";
static NSString *kPortKey = @"crazyNewPort";

@implementation FBWirelessInPatch

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8
{
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8
{
	return kQCPatchExecutionModeConsumer;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)identifier
{
  return kQCPatchTimeModeNone;
}

- (id)initWithIdentifier:(id)fp8
{
	if (self = [super initWithIdentifier:fp8]) {
    [[self userInfo] setObject:kInitialName forKey:@"name"];
 
    [self createPortOfType:@"Virtual"];
  }
  
	return self;
}

- (FBWirelessController *)controller {
  if (_controller == nil) {
    FBWirelessController *c = [FBWirelessController controllerForPatch:self];
    if (c) {
      self.controller = c;
    }
  }
  
  return _controller;
}

+ (Class)inspectorClassWithIdentifier:(id)fp8
{
	return [FBWirelessInPatchUI class];
}

- (void)setPortClass:(Class)aClass {
  NSString *type;
  
  if (aClass == [QCStringPort class]) {
    type = @"String";
  } else if (aClass == [QCNumberPort class]) {
    type = @"Number";
  } else if (aClass == [QCColorPort class]) {
    type = @"Color";
  } else if (aClass == [QCBooleanPort class]) {
    type = @"Boolean";
  } else if (aClass == [QCIndexPort class]) {
    type = @"Index";
  } else if (aClass == [QCImagePort class]) {
    type = @"Image";
  } else if (aClass == [QCStructurePort class]) {
    type = @"Structure";
  } else {
    type = @"Virtual";
  }
  
  [self setSelectedInputType:type];
}

- (void)createPortOfType:(NSString *)type {
  if (_inPort) {
    [self deleteInputForKey:kPortKey];
    _inPort = nil;
  }
  
  NSMutableDictionary *attributes = [[NSMutableDictionary alloc] initWithCapacity:2];
  [attributes setObject:@"Value" forKey:@"name"];
  
  Class portClass = [QCStringPort class];
  
  if (type && ![type isEqualToString:@"String"] && type.length > 0) {
    if ([type isEqualToString:@"Virtual"]) {
      portClass = [QCVirtualPort class];
    } else if ([type isEqualToString:@"Number"]) {
      portClass = [QCNumberPort class];
    } else if ([type isEqualToString:@"Color"]) {
      portClass = [QCColorPort class];
    } else if ([type isEqualToString:@"Boolean"]) {
      portClass = [QCBooleanPort class];
    } else if ([type isEqualToString:@"Index"]) {
      portClass = [QCIndexPort class];
    } else if ([type isEqualToString:@"Image"]) {
      portClass = [QCImagePort class];
    } else if ([type isEqualToString:@"Structure"]) {
      portClass = [QCStructurePort class];
    }
  }
  
  _selectedInputType = (type == nil || type.length < 1) ? @"String" : type;
  _inPort = [self createInputWithPortClass:portClass forKey:kPortKey attributes:attributes arguments:nil order:-1];
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments
{
  if (self.controller == nil) {
    NSLog(@"Wireless broadcaster can't find controller");
  }
  
  NSString *customName = [[self userInfo] objectForKey:@"name"];
  
  if (![customName isEqualToString:kInitialName]) {
    NSInteger keyCount = self.controller.keyedData.count;
    
    if ([_inPort value]) {
      [self.controller.keyedData setObject:[_inPort value] forKey:customName];
    } else {
      [self.controller.keyedData setObject:[NSNull null] forKey:customName];
    }
    
    if (keyCount < self.controller.keyedData.count) {
      self.controller.lastCreatedKey = customName;
    }
    
    [self.controller.keyedBroadcasters setObject:self forKey:customName];
    
    // Remove old key from dictionary on rename
    if (_previousName != nil && ![customName isEqualToString:_previousName]) {
      if ([self.controller.keyedData objectForKey:_previousName]) {
        [self.controller.keyedData removeObjectForKey:_previousName];
      }
      
      if ([self.controller.keyedBroadcasters objectForKey:_previousName]) {
        [self.controller.keyedBroadcasters removeObjectForKey:_previousName];
      }
    }
    
    _previousName = customName;
  }
  
	return YES;
}

- (void)disable:(QCOpenGLContext *)context {
  NSString *customName = [[self userInfo] objectForKey:@"name"];
  
  if (![customName isEqualToString:kInitialName] && self.controller) {
    if ([self.controller.keyedData objectForKey:customName])
      [self.controller.keyedData removeObjectForKey:customName];
    
    if ([self.controller.keyedBroadcasters objectForKey:customName])
      [self.controller.keyedBroadcasters removeObjectForKey:customName];
  }
}

- (NSDictionary *)state
{
	NSMutableDictionary *stateDict = [NSMutableDictionary dictionary];
	
	[stateDict addEntriesFromDictionary:[super state]];
  
  if (_previousName)
    [stateDict setObject:_previousName forKey:@"FBWirelessInPreviousName"];
  
  if (_selectedInputType)
    [stateDict setObject:_selectedInputType forKey:@"FBWirelessInInputType"];

  NSData *d;
  
  if (_inPort.baseClass == [QCBooleanPort class] || _inPort.baseClass == [QCStringPort class] || _inPort.baseClass == [QCIndexPort class] || _inPort.baseClass == [QCNumberPort class] || _inPort.baseClass == [QCColorPort class]) {
    d = [NSKeyedArchiver archivedDataWithRootObject:[_inPort value]];
  } else {
    d = [NSKeyedArchiver archivedDataWithRootObject:[NSNull null]];
  }

  if (d)
    [stateDict setObject:d forKey:@"FBWirelessInPortValue"];
	
	return stateDict;
}

- (BOOL)setState:(NSDictionary *)state
{
  _previousName = [[state objectForKey:@"FBWirelessInPreviousName"] copy];
  _selectedInputType = [[state objectForKey:@"FBWirelessInInputType"] copy];
  
  [self createPortOfType:_selectedInputType];
  
	id unarchivedValue = [NSKeyedUnarchiver unarchiveObjectWithData:[state objectForKey:@"FBWirelessInPortValue"]];
  [_inPort setValue:unarchivedValue];
  
	return [super setState:state];
}

- (void)setSelectedInputType:(NSString *)type {
  _selectedInputType = [type copy];

  [self createPortOfType:type];
}

- (id)nodeActorForView:(NSView *)view
{  
  Class QCMiniPatchActor = objc_getClass("QCMiniPatchActor");
  id actor = [QCMiniPatchActor sharedActor];

  return actor;
}

@end
