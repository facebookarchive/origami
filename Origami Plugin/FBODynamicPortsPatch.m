/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBODynamicPortsPatch.h"

typedef enum FBOPortType : NSUInteger {
  FBOPortTypeInput,
  FBOPortTypeOutput,
  FBOPortTypeCount
} FBOPortType;

@interface FBODynamicPortsPatch (Private)
- (QCPort *)_addPort:(FBOPortType)portType named:(NSString *)portName withValue:(id)portValue ofType:(Class)portClass;
- (BOOL)_removePort:(FBOPortType)portType named:(NSString *)portName;
@end

@implementation FBODynamicPortsPatch

- (id)initWithIdentifier:(id)identifier {
	if (self = [super initWithIdentifier:identifier]) {
    _existingPorts = [[NSMutableDictionary alloc] init];
  }

	return self;
}

- (GFPort *)addInputPortNamed:(NSString *)portName ofType:(Class)portClass {
  return [self _addPort:FBOPortTypeInput named:portName withValue:nil ofType:portClass];
}

- (GFPort *)addOutputPortNamed:(NSString *)portName withValue:(id)portValue ofType:(Class)portClass {
  return [self _addPort:FBOPortTypeOutput named:portName withValue:portValue ofType:portClass];
}

- (BOOL)removeInputPortNamed:(NSString *)portName {
  return [self _removePort:FBOPortTypeInput named:portName];
}

- (BOOL)removeOutputPortNamed:(NSString *)portName {
  return [self _removePort:FBOPortTypeOutput named:portName];
}

- (void)setValue:(id)portValue forPortNamed:(NSString *)portName {
  if (!portValue) {
    Class portClass = [_existingPorts[portName] class];
    portValue = (portClass == [QCStringPort class]) ? @"" : [NSNull null];
  }

  if (portName) {
    [self __setValue:portValue forPortKey:portName];
  }
}

@end

@implementation FBODynamicPortsPatch (Private)

- (GFPort *)_addPort:(FBOPortType)portType
               named:(NSString *)portName
           withValue:(id)portValue
              ofType:(Class)portClass {

  portValue = portValue ? portValue : [NSNull null];

  NSMutableSet *existingPortConnections = [NSMutableSet set];
  BOOL portRemovedSuccessfully = YES;

  /* Do nothing if a pot name wasn't provided or is invalid. */
  if (!portName) {
    return nil;
  }

  if ([[_existingPorts allKeys] containsObject:portName]) {
    Class existingPortClass = [_existingPorts[portName] class];

    /* If this exact port already exists, set its value to that which was provided
       and then do nothing. Note that resetting the value is actually kinda weird. */
    if (portClass == existingPortClass) {
      [self setValue:portValue forPortNamed:portName];
      return nil;

    /* If a port with this name, but a different type exists, cache its current
       connections and remove the existing port. */
    } else {
      existingPortConnections = [self _connectionsForPortName:portName];
      portRemovedSuccessfully = [self _removePort:portType named:portName];
    }
  }

  /* If there was an unexpected error in removing an existing port of a different
     type, then bail. */
  if (!portRemovedSuccessfully) {return nil;}

  id createdPort;
  if (portType == FBOPortTypeInput) {
    createdPort = [self createInputWithPortClass:portClass
                                          forKey:portName
                                      attributes:@{@"description":@"", @"name":portName}];
  } else {
    createdPort = [self createOutputWithPortClass:portClass
                                           forKey:portName
                                       attributes:@{@"description":@"", @"name":portName}];
  }

  /* Bail if no port could be created. */
  if (!createdPort) {return nil;}

  [_existingPorts setValue:createdPort forKey:portName];
  [self setValue:portValue forPortNamed:portName];

  [self _restoreConnections:existingPortConnections toPort:createdPort];

  return createdPort;
}

-(NSMutableSet *)_connectionsForPortName:(NSString *)portName {
  NSMutableSet *portConnections = [NSMutableSet set];
  NSArray *compositionConnections = [[self parentPatch] connections];

  for (QCLink *connection in compositionConnections) {
    if ([[[connection sourcePort] key] isEqualToString:portName]) {
      GFPort *destinationPort = [connection destinationPort];
      if (destinationPort) {
        [portConnections addObject:destinationPort];
      }
    }
  }
  return portConnections;
}

-(void)_restoreConnections:(NSMutableSet*)connections toPort:(QCPort *)targetPort {
  if ([connections count]) {
    for (QCPort *port in connections) {
      if (port) {
        [[self parentPatch] createConnectionFromPort:targetPort toPort:port];
      }
    }
  }
}

- (BOOL)_removePort:(FBOPortType)portType named:(NSString *)portName {

  if ([[_existingPorts allKeys] containsObject:portName]) {
    NSArray *ports = (portType == FBOPortTypeInput) ? [self inputPorts] : [self outputPorts];
    for (QCPort *port in ports) {
      if ([[port key] isEqualToString:portName]) {
        if ([self isPortPublished:port]) {
          [self setValue:nil forPortNamed:portName];
          return NO;
        }

        if (portType == FBOPortTypeInput) {
          [self deleteInputPortForKey:portName];
        } else {
          [self deleteOutputPortForKey:portName];
        }

        [_existingPorts removeObjectForKey:portName];
        break;
      }
    }
  }

  return YES;
}


@end
