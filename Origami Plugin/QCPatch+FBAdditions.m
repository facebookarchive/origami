/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "QCPatch+FBAdditions.h"
#import "FBOrigamiAdditions.h"
#import "NSObject+AssociatedObjects.h"
#import "NSDocument+FBAdditions.h"

@implementation QCPatch (FBAdditions)

- (QCPatch *)fb_rootPatch {
  QCPatch *rootPatch = [self associatedValueForKey:@"fb_rootPatch"];
  
  if (!rootPatch) {
    rootPatch = ([self parentPatch]) ? [self parentPatch] : self;
    
    while ([rootPatch parentPatch] != nil) {
      rootPatch = [rootPatch parentPatch];
    }
  }

  return rootPatch;
}

- (NSDocument *)fb_document {
  NSDocument *document = [self associatedValueForKey:@"fb_document"];
  
  if (!document) {
    for (NSDocument *d in [[NSDocumentController sharedDocumentController] documents]) {
      if (d.fb_graph.fb_rootPatch == self.fb_rootPatch) {
        document = d;
      }
    }
  }

  return document;
}

- (NSSize)fb_cachedActorSize {
  NSMutableDictionary *actorSizeForNames = [self associatedValueForKey:@"fb_actorSizeForNames"];
  NSString *patchName = self.fb_name;
  NSValue *sizeValue = actorSizeForNames[patchName];
  
  if (sizeValue) {
    return sizeValue.sizeValue;
  }
  
  if (!actorSizeForNames) {
    actorSizeForNames = [NSMutableDictionary dictionary];
  }

  NSSize size = self.fb_actorSize;
  actorSizeForNames[patchName] = [NSValue valueWithSize:size];
  
  [self associateValue:actorSizeForNames withKey:@"fb_actorSizeForNames"];
  
  return size;
}

// The patch must be in a graph for this to work
- (QCPatchActor *)fb_actor {
  return [self.fb_document.fb_patchView nodeActorForNode:self];
}

- (NSSize)fb_actorSize {
  NSSize size = [self.fb_actor sizeForNode:self];
  return size;
}

- (NSSize)fb_actorSizeInKeyPatchView {
  QCPatchActor *actor = [self nodeActorForView:[[FBOrigamiAdditions sharedAdditions] patchView]];
  NSSize size = [actor sizeForNode:self];
  return size;
}

- (NSPoint)fb_actorPosition {
  NSValue *positionValue = self.userInfo[@"position"];
  return positionValue.pointValue;
}

- (void)fb_setActorPosition:(NSPoint)position {
  self.userInfo[@"position"] = [NSValue valueWithPoint:position];
}

// GFNameForNode() equivalent
- (NSString *)fb_name {
  NSString *name = [[self userInfo] objectForKey:@"name"];
  
  if (name)
    return name;
  
  name = [[self attributes] objectForKey:@"name"];
  
  if (!name)
    name = [self fb_classNameForNode];
  
  return name;
}

// _ClassNameForNode() equivalent
- (NSString *)fb_classNameForNode {
  NSString *className = nil;
  
  if ([[self identifier] length]) {
    className = [NSString stringWithFormat:@"%@ (%@)",NSStringFromClass([self class]),[self identifier]];
  } else {
    className = NSStringFromClass([self class]);
  }
  
  return className;
}

- (NSString *)fb_className {
  NSString *patchClassName = self.userInfo[@".className"];
  
  if (!patchClassName)
    patchClassName = NSStringFromClass([self class]);
  
  return patchClassName;
}

- (NSString *)description {
  QCPatch *namedParent = self;
  
  while (namedParent != nil && !namedParent.userInfo[@"name"]) {
    namedParent = [namedParent parentPatch];
  }
  
  return [NSString stringWithFormat:@"<%@ %p \"%@\" in \"%@\">",NSStringFromClass([self class]),self,self.fb_name,namedParent.fb_name];
}

@end
