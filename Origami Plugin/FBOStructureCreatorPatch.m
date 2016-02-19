/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOStructureCreatorPatch.h"
#import "FBOStructureCreatorPatchUI.h"
#import "QCPort+FBAdditions.h"

@implementation FBOStructureCreatorPatch

+ (NSArray*)stateKeysWithIdentifier:(id)identifier {
  return @[@"inputCount", @"portClass", @"keyed"];
}

// Disable automatic serialization which doesn't seem to support Class objects. We manually serialize classes as strings instead.
+ (id)serializedStateKeysWithIdentifier:(id)arg1 {
  return nil;
}

+ (BOOL)allowsSubpatchesWithIdentifier:(id)identifier {
  return NO;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)identifier {
  return kQCPatchExecutionModeProcessor;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)identifier {
  return kQCPatchTimeModeNone;
}

+ (Class)inspectorClassWithIdentifier:(id)identifier {
  return [FBOStructureCreatorPatchUI class];
}

- (id)initWithIdentifier:(id)identifier {
  if (self = [super initWithIdentifier:identifier]) {
    if (!_portClassInternal) {
      _portClassInternal = [QCVirtualPort class];
    }
    
    if (self.inputCount < 1){
      self.inputCount = 2;
    }
  }
  return self;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
  QCStructure *structure = nil;

  if (!_keyed) {
    NSMutableArray *array = [NSMutableArray array];
    for (QCPort *valuePort in self.inputPorts) {
      id value = valuePort.value;
      if (!value)
        value = @NO;
      
      [array addObject:value];
    }
    structure = [[QCStructure alloc] initWithArray:array];
  }
  else {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSArray *inputPorts = self.inputPorts;
    for (int i = 0; i < (inputPorts.count / 2); i++) {
      QCStringPort *keyPort = inputPorts[i*2];
      QCPort *valuePort = inputPorts[((i*2)+1)];
      
      NSString *key = keyPort.stringValue;

      if (key.length > 0) {
        id value = valuePort.value;
        if (!value)
          value = @NO;
        
        dictionary[key] = value;
      }
    }
    structure = [[QCStructure alloc] initWithDictionary:dictionary];
  }

  [outputStructure setStructureValue:structure];
  
  return YES;
}


#pragma mark - Port Count

- (void)setInputCount:(NSUInteger)newInputCount {
  NSUInteger newIndex = newInputCount - 1;
  NSUInteger oldIndex = _inputCount - 1;

  if (_inputCount == 0 && newInputCount > 0){
    for (int i = 0; i < newInputCount; i++) {
      if (self.keyed)
        [self addKeyPortWithIndex:i];

      [self _addPortNumber:i class:nil];
    }
  } else if (newInputCount > _inputCount){
    while (oldIndex < newIndex){
      oldIndex++;
      
      if (self.keyed)
        [self addKeyPortWithIndex:oldIndex];
      
      [self _addPortNumber:oldIndex class:[self portClass]];
    }
  } else if (newInputCount < _inputCount){
    for (; oldIndex > newIndex && newInputCount > 0; oldIndex--) {
      [self _removePortNumber:oldIndex];
      
      if (self.keyed) {
        NSString *portName = [NSString stringWithFormat:@"Key %lu",(unsigned long)oldIndex];
        [self removeInputPortNamed:portName];
      }
    }
  }
  
  _inputCount = newInputCount > 0 ? newInputCount : _inputCount;
}

- (NSString *)nameForPortNumber:(NSUInteger)number{
  return [NSString stringWithFormat:@"Input %lu", (unsigned long)number];
}

- (QCPort *)_addPortNumber:(NSUInteger)number class:(Class)portClass {
  if (!portClass)
    portClass = [QCVirtualPort class];
  
  QCPort *port = (QCPort *)[self addInputPortNamed:[self nameForPortNumber:number] ofType:portClass];
  [(QCBooleanPort *)port setValue:NO];
  return port;
}

- (void)_removePortNumber:(NSUInteger)number {
  [self removeInputPortNamed:[self nameForPortNumber:number]];
}

#pragma mark - Port Type

- (void)resetPortType:(Class)portClass {
  NSArray *inputPorts = [NSArray arrayWithArray:self.inputPorts];
  
  NSMutableArray *portConnections = [NSMutableArray array];
  
  for (QCPort *inputPort in inputPorts) {
    NSString *portName = inputPort.attributes[@"name"];
    
    if (![portName hasPrefix:@"Key"]) {
      // Save connections
      [portConnections addObject:inputPort.fb_connectedPorts];
      
      // Remove the port
      [self removeInputPortNamed:portName];
    }
  }
  
  for (int i = 0; i < inputPorts.count; i++) {
    QCPort *inputPort = inputPorts[i];
    NSString *portName = inputPort.attributes[@"name"];

    if (![portName hasPrefix:@"Key"]) {
      // Add the new port
      NSUInteger portNumber = self.keyed ? i/2 : i;
      QCPort *newPort = [self _addPortNumber:portNumber class:portClass];
      
      // Move the port to the correct position
      if (self.keyed)
        [self setInputOrder:i forKey:newPort.key];
      
      // Restore connections
      NSArray *connectedPorts = portConnections[portNumber];
      for (QCPort *connectedPort in connectedPorts) {
        [self.parentPatch createConnectionFromPort:connectedPort toPort:newPort];
      }
    }
  }
}

- (Class)portClassForType:(NSString *)type {
  if (!type)
    return [QCVirtualPort class];
  
  return NSClassFromString([NSString stringWithFormat:@"QC%@Port",type]);
}

- (BOOL)setState:(NSDictionary *)state {
  NSNumber *count = state[@"inputCount"];
  self.inputCount = count.unsignedIntegerValue;
  
  NSString *class = state[@"portClass"];
  self.portClass = NSClassFromString(class);
  
  NSNumber *keyed = state[@"keyed"];
  self.keyed = keyed.boolValue;
  
  BOOL superSuccess = [super setState:state];
  
  BOOL restoreSuccess = [self restoreCustomInputPortStates:self.inputPorts fromState:state];
  
  return (superSuccess && restoreSuccess);
}

- (NSDictionary *)state {
  NSMutableDictionary *state = (NSMutableDictionary *)[super state];
  
  state[@"portClass"] = NSStringFromClass(self.portClass);
  state[@"inputCount"] = @(self.inputCount);
  state[@"keyed"] = @(self.keyed);
  
  [self saveCustomInputPortStates:self.inputPorts toState:state];
  
  return state;
}

- (Class)portClass {
  return _portClassInternal;
}

- (void)setPortClass:(Class)aClass {
  if (!aClass)
    return;
  
  if (aClass != _portClassInternal) {
    _portClassInternal = aClass;
    [self resetPortType:aClass];
  }
}

#pragma mark - Keys

- (void)setKeyed:(BOOL)keyed {
  if (!_keyed && keyed)
    [self addKeyPorts];
  else if (_keyed && !keyed)
    [self removeKeyPorts];

  _keyed = keyed;
}

- (void)addKeyPorts {
  NSArray *inputPorts = [NSArray arrayWithArray:self.inputPorts];
  NSMutableArray *keyPorts = [NSMutableArray array];
  
  // Add new string ports to the patch for containing keys
  for (int i = 0; i < inputPorts.count; i++) {
    QCStringPort *keyPort = [self addKeyPortWithIndex:i];
    [keyPorts addObject:keyPort];
  }
  
  // Move the key ports before the related value ports
  for (int i = 0; i < keyPorts.count; i++) {
    QCStringPort *keyPort = keyPorts[i];
    [self setInputOrder:i*2 forKey:keyPort.key];
  }
}

- (QCStringPort *)addKeyPortWithIndex:(NSUInteger)index {
  NSString *portName = [NSString stringWithFormat:@"Key %lu",(unsigned long)index];
  QCStringPort *port = (QCStringPort *)[self addInputPortNamed:portName ofType:[QCStringPort class]];
  port.stringValue = @"";
  return port;
}

- (void)removeKeyPorts {
  NSArray *inputPorts = [NSArray arrayWithArray:self.inputPorts];
  
  for (QCPort *port in inputPorts) {
    NSString *portName = port.attributes[@"name"];
    
    if ([portName hasPrefix:@"Key"])
      [self removeInputPortNamed:portName];
  }
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ([keyPath isEqualToString:@"inputCount"]) {
    [self setValue:[object valueForKey:keyPath] forStateKey:@"inputCount"];
  }
  else if ([keyPath isEqualToString:@"inputType"]) {
    NSString *type = [object valueForKey:keyPath];
    [self setValue:[self portClassForType:type] forStateKey:@"portClass"];
  }
  else if ([keyPath isEqualToString:@"keyed"]) {
    [self setValue:[object valueForKey:keyPath] forStateKey:@"keyed"];
  }
}

@end
