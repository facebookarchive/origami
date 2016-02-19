/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBOMultiSwitchPatch.h"
#import "FBOMultiSwitchPatchUI.h"

@implementation FBOMultiSwitchPatch

#pragma mark - QCPatch Characteristics

/**
 This is nessecary for QC to archive the state of this patch. Keys listed here
 in addition to `userInfo` and other built-in state information will be persisted,
 and reset by `setState:` when patches are restored.
 */
+ (NSArray*)stateKeysWithIdentifier:(id)identifier { return @[@"inputCount"]; }

+ (BOOL)allowsSubpatchesWithIdentifier:(id)identifier { return NO; }
+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)identifier {return kQCPatchExecutionModeProcessor;}
+ (Class)inspectorClassWithIdentifier:(id)identifier {return [FBOMultiSwitchPatchUI class];}
+ (QCPatchTimeMode)timeModeWithIdentifier:(id)identifier {return kQCPatchTimeModeIdle;}

#pragma mark - Patch Behavior

/**
 Creates a Multi Switch with three inputs by default.
 */
- (id)initWithIdentifier:(id)identifier {
  if (self = [super initWithIdentifier:identifier]) {
    if ([self integerForStateKey:@"inputCount"] < 1){
      [self setValue:@3 forStateKey:@"inputCount"];
    }
  }
	return self;
}

/**
 Creates or removes input ports from the patch based on changes to the
 `inputCount` property.
 */
- (void)setInputCount:(NSUInteger)newInputCount {
  double newIndex = newInputCount - 1;
  double oldIndex = _inputCount - 1;

  if (_inputCount == 0 && newInputCount > 0){
    for (int i = 0; i < newInputCount;i++) {
      [self _addPortNumber:i];
    }
  } else if (newInputCount > _inputCount){
    while (oldIndex < newIndex){
      oldIndex++;
      [self _addPortNumber:oldIndex];
    }
  } else if (newInputCount < _inputCount){
    for (; oldIndex > newIndex && newInputCount > 0; oldIndex--) {
      [self _removePortNumber:oldIndex];
    }
  }
  _inputCount = newInputCount > 0 ? newInputCount : _inputCount;
}

/**
 Sets the output port with the index of the *last* input port that changed
 and is currently high.
 */
- (BOOL)execute:(QCOpenGLContext *)context
           time:(double)time
      arguments:(NSDictionary *)arguments
{
  NSUInteger portIndex = 0;
  for (QCBooleanPort* port in [self customInputPorts]){
    if ([port wasUpdated] && port.booleanValue){
      outputIndex.indexValue = portIndex;
    }
    portIndex++;
  }
  return YES;
}

#pragma mark - Port Management

- (NSString *)nameForPortNumber:(NSUInteger) number{
  return [NSString stringWithFormat:@"Input %lu", (unsigned long)number];
}

- (QCBooleanPort *)_addPortNumber:(NSUInteger)number {
  QCBooleanPort *port = (QCBooleanPort *)[self addInputPortNamed:[self nameForPortNumber:number] ofType:[QCBooleanPort class]];
  [port setValue:NO];
  return port;
}

- (void)_removePortNumber:(NSUInteger)number {
  [self removeInputPortNamed:[self nameForPortNumber:number]];
}

#pragma mark - NSKeyValueObserving

/**
 Instances of `FBOMultiSwitchPatchUI` trigger this whenever the UI's `inputCount`
 changes. Because QCPatch uses `stateKey` instead of just `key`, a direct binding
 between the UI and the patch count isn't possible, so this method basically does that.
 */
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                        context:(void *)context
{
  if ([keyPath isEqualToString:@"inputCount"]){
    [self setValue:[object valueForKey:keyPath] forStateKey:@"inputCount"];
  }
}

@end
