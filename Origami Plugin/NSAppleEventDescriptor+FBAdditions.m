/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "NSAppleEventDescriptor+FBAdditions.h"
#import "NSDate+FBAdditions.h"
#import "NSURL+FBAdditions.h"

static NSString *NSAppleScriptDescriptorTypeBooleanTrue = @"'true'";
static NSString *NSAppleScriptDescriptorTypeBooleanFalse = @"'fals'";
static NSString *NSAppleScriptDescriptorTypeString = @"'utxt'";
static NSString *NSAppleScriptDescriptorTypeEnum = @"'enum'";
static NSString *NSAppleScriptDescriptorTypeDouble = @"'doub'";
static NSString *NSAppleScriptDescriptorTypeLong = @"'long'";
static NSString *NSAppleScriptDescriptorTypeTIFFImage = @"'TIFF'";
static NSString *NSAppleScriptDescriptorTypeJPEGImage = @"'JPEG'";
static NSString *NSAppleScriptDescriptorTypeTDTAImage = @"'tdta'";
static NSString *NSAppleScriptDescriptorTypeNull = @"'null'";
static NSString *NSAppleScriptDescriptorTypeObject = @"'obj '";
static NSString *NSAppleScriptDescriptorTypeList = @"'list'";
static NSString *NSAppleScriptDescriptorTypeRecord = @"'reco'";
static NSString *NSAppleScriptDescriptorTypeAlias = @"'alis'";
static NSString *NSAppleScriptDescriptorTypeDate = @"'ldt '";

@implementation NSAppleEventDescriptor (DHTools)

- (id)objectValue {
  DescType descriptorTypeCode = [self descriptorType];
  
  if (descriptorTypeCode == NSHFSTypeCodeFromFileType(NSAppleScriptDescriptorTypeNull)) {
    return [NSNull null];
    
  } else if (descriptorTypeCode == NSHFSTypeCodeFromFileType(NSAppleScriptDescriptorTypeBooleanTrue)) {
    return @(YES);
    
  } else if (descriptorTypeCode == NSHFSTypeCodeFromFileType(NSAppleScriptDescriptorTypeBooleanFalse)) {
    return @(NO);
    
  } else if (descriptorTypeCode == NSHFSTypeCodeFromFileType(NSAppleScriptDescriptorTypeString) ||
             descriptorTypeCode == NSHFSTypeCodeFromFileType(NSAppleScriptDescriptorTypeEnum)) {
    return self.stringValue;
    
  } else if (descriptorTypeCode == NSHFSTypeCodeFromFileType(NSAppleScriptDescriptorTypeDouble) ||
             descriptorTypeCode == NSHFSTypeCodeFromFileType(NSAppleScriptDescriptorTypeLong)) {
    return [NSNumber numberWithDouble:[self.stringValue doubleValue]];
    
  } else if (descriptorTypeCode == NSHFSTypeCodeFromFileType(NSAppleScriptDescriptorTypeTIFFImage) ||
             descriptorTypeCode == NSHFSTypeCodeFromFileType(NSAppleScriptDescriptorTypeTDTAImage) ||
             descriptorTypeCode == NSHFSTypeCodeFromFileType(NSAppleScriptDescriptorTypeJPEGImage)) {
    NSData *imageData = self.data;
    return imageData ? [[NSImage alloc] initWithData:self.data] : nil;
    
  } else if (descriptorTypeCode == NSHFSTypeCodeFromFileType(NSAppleScriptDescriptorTypeObject)) {
    return self.description;
  } else if (descriptorTypeCode == NSHFSTypeCodeFromFileType(NSAppleScriptDescriptorTypeAlias)) {
    return [NSURL URLWithEventDescriptor:self];
  } else if (descriptorTypeCode == NSHFSTypeCodeFromFileType(NSAppleScriptDescriptorTypeDate)) {
    return [NSDate dateWithEventDescriptor:self];
  } else if (descriptorTypeCode == NSHFSTypeCodeFromFileType(NSAppleScriptDescriptorTypeList) ||
             descriptorTypeCode == NSHFSTypeCodeFromFileType(NSAppleScriptDescriptorTypeRecord)) {
    NSUInteger numberOfItems = self.numberOfItems;
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:numberOfItems];
    NSUInteger index;
    for (index = 1; index < (numberOfItems + 1); index++) {
      id object = [self descriptorAtIndex:index].objectValue;
      if (!object) {
        object = [NSNull null];
      }
      [array addObject:object];
    }
    return array;
  } else {
    NSLog(@"Unkown Type: %@", NSFileTypeForHFSTypeCode(descriptorTypeCode));
    return self.stringValue;
  }
}

@end
