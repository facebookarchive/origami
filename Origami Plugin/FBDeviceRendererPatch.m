/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBDeviceRendererPatch.h"
#import "BWDeviceInfoReceiver.h"
#import "QCImage+FBAdditions.h"
#import "FBMutableOrderedDictionary.h"

#define BW_MEASURE NSLog(@"Date %d: %.3f",__LINE__, [[NSDate date] timeIntervalSinceDate:date]*1000.0);date = [NSDate date]

static CGFloat previousTime = 0;
static NSUInteger queueIndexCounter = 0;
static BOOL needsTreeSerialization, shouldSerializeTreeThisFrame;

// Replace NaNs with 0
static inline double FBNanKiller(double value) {
  return (value != value) ? 0 : value;
}

static inline CGFloat FBNanKillerF(CGFloat value) {
  return (value != value) ? 0 : value;
}

@interface FBDeviceRendererPatch ()
- (NSString *)layerKey;
@property (readonly) NSString *spriteName;
@property (readonly) BOOL isInIterator;
@property NSMutableArray *updatedPortKeysInIterator;
@property NSMutableArray *patchIDs; // IDs of patches owned by this patch. The array will only have more than one ID in an iterator.
@end

@implementation FBDeviceRendererPatch

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8
{
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)fp8
{
	return kQCPatchExecutionModeConsumer;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)fp8
{
	return kQCPatchTimeModeTimeBase;
}

- (id)initWithIdentifier:(id)fp8
{
	if (self = [super initWithIdentifier:fp8]) {
    [[self userInfo] setObject:@"Device Renderer" forKey:@"name"];
    
    [inputAlpha setMinDoubleValue:0.0];
    [inputAlpha setMaxDoubleValue:1.0];
    
    _basePatchID = arc4random_uniform(999999) * 1000;
    _patchID = _basePatchID;
    
    [[BWDeviceInfoReceiver sharedReceiver] patchRequestsConnection];
    
    self.updatedPortKeysInIterator = [NSMutableArray array];
    self.patchIDs = [NSMutableArray array];
  }
  
	return self;
}

- (NSString *)layerKey {
  return [NSString stringWithFormat:@"%u",_patchID];
}

- (BOOL)RIIIsValid:(NSString *)attachedRII {
  BOOL RIIisNonNil = !(attachedRII == nil || [attachedRII isEqualToString:@""] || [attachedRII isEqualToString:@"0"]);
  
  BOOL attachedRIIisParent = NO;
  if ([[BWDeviceInfoReceiver sharedReceiver].parentRIIs.allValues containsObject:attachedRII]) {
    attachedRIIisParent = YES;
  }

  return (RIIisNonNil && attachedRIIisParent);
}

- (BOOL)portWasUpdated:(QCPort *)port {
  BOOL portWasUpdated = [port wasUpdated];
  
  if (self.isInIterator)
    portWasUpdated = [self.updatedPortKeysInIterator containsObject:[port key]];

  return portWasUpdated;
}

- (BOOL)isInIterator {
  return ([inputIterationCount indexValue] > 0);
}

- (NSDictionary *)serializedRepresentationOfType:(FBSerializationType)type {
  NSMutableDictionary *changes = [NSMutableDictionary dictionary];
  BOOL serializeAll = (type == FBSerializationTypeAll);
  
  if (serializeAll) {
    NSString *parentRII = [NSString stringWithFormat:@"%u",_parentRIIHash];
    [changes setObject:parentRII forKey:@"parentRII"];
    [changes setObject:self.layerKey forKey:@"id"];
  }
  
  if ([self portWasUpdated:inputXPosition] || serializeAll)
    [changes setObject:[NSNumber numberWithDouble:FBNanKiller([inputXPosition doubleValue])] forKey:@"x"];
  
  if ([self portWasUpdated:inputYPosition] || serializeAll)
    [changes setObject:[NSNumber numberWithDouble:FBNanKiller([inputYPosition doubleValue])] forKey:@"y"];
  
  if ([self portWasUpdated:inputZPosition] || serializeAll)
    [changes setObject:[NSNumber numberWithDouble:FBNanKiller([inputZPosition doubleValue])] forKey:@"z"];
  
  if ([self portWasUpdated:inputWidth] || serializeAll)
    [changes setObject:[NSNumber numberWithDouble:FBNanKiller([inputWidth doubleValue])] forKey:@"width"];
  
  if ([self portWasUpdated:inputHeight] || serializeAll)
    [changes setObject:[NSNumber numberWithDouble:FBNanKiller([inputHeight doubleValue])] forKey:@"height"];
  
  if ([self portWasUpdated:inputAlpha] || serializeAll)
    [changes setObject:[NSNumber numberWithDouble:FBNanKiller([inputAlpha doubleValue])] forKey:@"alpha"];
  
  if ([self portWasUpdated:inputScale] || [self portWasUpdated:inputXRotation] || [self portWasUpdated:inputYRotation] || [self portWasUpdated:inputZRotation] || serializeAll) {
    [changes setObject:[NSNumber numberWithDouble:FBNanKiller([inputScale doubleValue])] forKey:@"scale"];
    [changes setObject:[NSNumber numberWithDouble:FBNanKiller([inputXRotation doubleValue])] forKey:@"xRotation"];
    [changes setObject:[NSNumber numberWithDouble:FBNanKiller([inputYRotation doubleValue])] forKey:@"yRotation"];
    [changes setObject:[NSNumber numberWithDouble:FBNanKiller([inputZRotation doubleValue])] forKey:@"zRotation"];
  }
  
  if ([self portWasUpdated:inputColor] || serializeAll || ([self portWasUpdated:inputImage] && [inputImage imageValue] == nil)) {
    [changes setObject:[NSNumber numberWithFloat:FBNanKillerF([inputColor redComponent])] forKey:@"colorR"];
    [changes setObject:[NSNumber numberWithFloat:FBNanKillerF([inputColor greenComponent])] forKey:@"colorG"];
    [changes setObject:[NSNumber numberWithFloat:FBNanKillerF([inputColor blueComponent])] forKey:@"colorB"];
  }
  
  QCRenderInImage *riiPatch = [inputImage.imageValue metadataForKey:@"FBAttachedRII"];
  uint32_t attachedRIIHashInt = (uint32_t)[riiPatch hash];
  NSString *attachedRIIHash = [NSString stringWithFormat:@"%u",attachedRIIHashInt];
  
  if (serializeAll) {
    [changes setObject:attachedRIIHash forKey:@"attachedRII"];
  }

  BOOL hasNoChildren = ![self RIIIsValid:attachedRIIHash];
  
  // This is to keep both viewers consistent with our rate limiting
  BOOL imageIsPossiblyDirty = ([BWDeviceInfoReceiver sharedReceiver].layersThatJustHadLimitRemoved[self.layerKey] != nil);

  if (([self portWasUpdated:inputImage] || imageIsPossiblyDirty || serializeAll) && hasNoChildren) {
    NSLog(@"sending img. imageWasUpdated: %d, imageIsPossiblyDirty: %d, serializeAll: %d, hasNoChildren: %d",[self portWasUpdated:inputImage],imageIsPossiblyDirty,serializeAll,hasNoChildren);
    if (imageIsPossiblyDirty)
      [[BWDeviceInfoReceiver sharedReceiver].layersThatJustHadLimitRemoved removeObjectForKey:self.layerKey];
    
    QCImage *qcImage = [inputImage imageValue];
    if (qcImage) {
      NSString *imageHash = [qcImage fb_providerMD5];
      [changes setObject:imageHash forKey:@"image"];
      [[BWDeviceInfoReceiver sharedReceiver] encodeAndSendImage:qcImage hash:imageHash layerKey:self.layerKey];
    } else {
      [changes setObject:@"" forKey:@"image"];
    }
  }
  
  if (([self portWasUpdated:inputMaskImage] || serializeAll)) {
    QCImage *maskImage = [inputMaskImage imageValue];
    if (maskImage) {
      NSString *imageHash = [maskImage fb_providerMD5];
      [changes setObject:imageHash forKey:@"maskImage"];
      [[BWDeviceInfoReceiver sharedReceiver] encodeAndSendImage:maskImage hash:imageHash layerKey:self.layerKey];
    } else {
      [changes setObject:@"" forKey:@"maskImage"];
    }
  }
  
  return [NSDictionary dictionaryWithDictionary:changes];
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
  _patchID = _basePatchID + inputIterationIndex.indexValue; // Imposes a 999 iteration constraint
  
  BOOL frameDidStart = (previousTime != time);
  previousTime = time;
  
  if ([[BWDeviceInfoReceiver sharedReceiver] isConnected] == NO) {
    return YES;
  }
 
//  NSLog(@"execute. time: %f id: %u count: %lu frame: %lu z updated: %d",time,_patchID,inputIterationCount.indexValue,inputFrameNumber.indexValue,inputZRotation.wasUpdated);

  
  if (frameDidStart) {
    [self previousFrameDidEnd];
    
    queueIndexCounter = 0;
  }
  
  if (((_cachedQueueIndex != queueIndexCounter) && (inputFrameNumber.indexValue > 1) && (inputIterationIndex.indexValue == 0)) || inputIterationCount.wasUpdated) {
    needsTreeSerialization = YES;
  }

  if (inputIterationIndex.indexValue == 0) {
    _cachedQueueIndex = queueIndexCounter;
    queueIndexCounter++;
    [self.patchIDs removeAllObjects];
  }
  
  [self.patchIDs addObject:self.layerKey];
  
  if (self.isInIterator && inputIterationIndex.indexValue == 0) {
    [self.updatedPortKeysInIterator removeAllObjects];
    
    for (QCPort *port in self.inputPorts) {
      if (port.wasUpdated && port != inputIterationIndex && port != inputFrameNumber) {
        [self.updatedPortKeysInIterator addObject:[port key]];
      }
    }
  }
  
  if (frameDidStart) {
    shouldSerializeTreeThisFrame = needsTreeSerialization;
    needsTreeSerialization = NO;
  }
  
  if (shouldSerializeTreeThisFrame) {
    NSDictionary *serializedLayer = [self serializedRepresentationOfType:FBSerializationTypeAll];
    [[BWDeviceInfoReceiver sharedReceiver].layerTreeQueue setObject:serializedLayer forKey:self.layerKey];
  } else {
    NSDictionary *serializedLayer = [self serializedRepresentationOfType:FBSerializationTypeChange];
    if (serializedLayer.count > 0)
      [[BWDeviceInfoReceiver sharedReceiver].layerChanges setObject:serializedLayer forKey:self.layerKey];
  }
  
	return YES;
}

- (void)previousFrameDidEnd {
  if (shouldSerializeTreeThisFrame) {
    NSArray *tree = [self treeFromFlatList:[BWDeviceInfoReceiver sharedReceiver].layerTreeQueue.allValues];
    [[BWDeviceInfoReceiver sharedReceiver] sendData:tree forFrameType:FBFrameTypeLayerTree];
    shouldSerializeTreeThisFrame = NO;
  } else {
    if ([BWDeviceInfoReceiver sharedReceiver].layerChanges.count > 0)
      [[BWDeviceInfoReceiver sharedReceiver] sendData:[BWDeviceInfoReceiver sharedReceiver].layerChanges forFrameType:FBFrameTypeLayerChanges];
  }

  [[BWDeviceInfoReceiver sharedReceiver].layerTreeQueue removeAllObjects];
  [[BWDeviceInfoReceiver sharedReceiver].layerChanges removeAllObjects];
}

+ (void)setNeedsTreeSerialization {
  needsTreeSerialization = YES;
}

- (NSArray *)treeFromFlatList:(NSArray *)list {
  // Assumes the list is in order of children to parents and in the correct layer order for each level of hierarchy
  NSMutableArray *tree = [NSMutableArray array];
  NSMutableDictionary *attachedRIIs = [NSMutableDictionary dictionary];
  
  for (int i = list.count - 1; i >= 0; i--)
  {
    NSMutableDictionary *layerDict = [[list objectAtIndex:i] mutableCopy];
    NSString *attachedRII = [layerDict objectForKey:@"attachedRII"];
    if ([self RIIIsValid:attachedRII]) {
      [attachedRIIs setObject:layerDict forKey:attachedRII];
    }
    
    NSString *parentRII = [layerDict objectForKey:@"parentRII"];
    NSMutableDictionary *parentLayerDict = [attachedRIIs objectForKey:parentRII];
    if (parentLayerDict != nil) {
      // Add as a child
      NSMutableArray *children = [parentLayerDict objectForKey:@"children"];
      if (children == nil) {
        children = [NSMutableArray arrayWithObject:layerDict];
        [parentLayerDict setObject:children forKey:@"children"];
      } else {
        [children insertObject:layerDict atIndex:0];
      }
    } else {
      // Add to top level
      [tree insertObject:layerDict atIndex:0];
    }
  }
  
  return [NSArray arrayWithArray:tree];
}

- (void)searchForParentRII {
  QCPatch *parentRII = [self parentPatch];
  
  while (parentRII != nil && ![parentRII isKindOfClass:NSClassFromString(@"QCRenderInImage")]) {
    parentRII = [parentRII parentPatch];
  }
  
  if ([parentRII isKindOfClass:NSClassFromString(@"QCRenderInImage")]) {
    _parentRIIHash = (uint32_t)[parentRII hash];
    NSString *hashString = [NSString stringWithFormat:@"%u",_parentRIIHash];
    [[BWDeviceInfoReceiver sharedReceiver].parentRIIs setObject:hashString forKey:self.layerKey];
  }
}

- (void)enable:(QCOpenGLContext*)context {
  [self searchForParentRII];

  needsTreeSerialization = YES;
  
  _cachedQueueIndex = queueIndexCounter;
  queueIndexCounter++;
}

- (void)disable:(QCOpenGLContext*)context {
  _parentRIIHash = 0;
  _cachedQueueIndex = 0;
  [[BWDeviceInfoReceiver sharedReceiver].parentRIIs removeObjectForKey:self.layerKey];

  [[BWDeviceInfoReceiver sharedReceiver] sendData:self.patchIDs forFrameType:FBFrameTypeLayerRemoval withTag:PTFrameNoTag];
}

- (NSString *)spriteName {
  // Assumes the this patch is a direct subpatch of a Layer
  return [[[self parentPatch] userInfo] objectForKey:@"name"];
}

@end
