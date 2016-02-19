/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

@interface FBODynamicPortsPatch : QCPatch
{
  NSMutableDictionary *_existingPorts;
}

- (GFPort *)addInputPortNamed:(NSString *)portName ofType:(Class)portClass;
- (GFPort *)addOutputPortNamed:(NSString *)outputPortName withValue:(id)outputPortValue ofType:(Class)outputPortClass;

- (BOOL)removeInputPortNamed:(NSString *)portName;
- (BOOL)removeOutputPortNamed:(NSString *)outputPortName;

- (void)setValue:(id)portValue forPortNamed:(NSString *)portName;

@end
