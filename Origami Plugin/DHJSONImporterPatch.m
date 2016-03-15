/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "DHJSONImporterPatch.h"
#import "SBJson.h"
#import "NSURL+FBAdditions.h"
#import "QCPatch+FBAdditions.h"

@implementation DHJSONImporterPatch

- (id)initWithIdentifier:(id)identifier {
	if (self = [super initWithIdentifier:identifier]) {
        inputUpdateSignal.booleanValue = YES;
    }
    
	return self;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)identifier {
	return kQCPatchExecutionModeProcessor;
}

+ (BOOL)allowsSubpatchesWithIdentifier:(id)identifier {
	return NO;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)identifier {
	return kQCPatchTimeModeIdle;
}

- (void)_execute:(id)sender {
    outputDoneSignal.booleanValue = NO;
    
    if (!(inputJSONLocation.wasUpdated || (inputUpdateSignal.wasUpdated && inputUpdateSignal.booleanValue == YES))) {
        return;
    }
    
    SBJsonParser *parser = [[SBJsonParser alloc] init];
    
    NSError *error;
    NSURL *url = [NSURL URLWithQuartzComposerLocation:inputJSONLocation.stringValue relativeToDocument:self.fb_document];
    NSString *jsonText = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];

    NSUInteger arrayStartLocation = [jsonText rangeOfString:@"["].location;
    NSUInteger dictionaryStartLocation = [jsonText rangeOfString:@"{"].location;
    NSUInteger startLocation = NSNotFound;
    
    if (arrayStartLocation == NSNotFound) {
        startLocation = dictionaryStartLocation;
    } else if (dictionaryStartLocation == NSNotFound) {
        startLocation = arrayStartLocation;
    } else {
        startLocation = MIN(arrayStartLocation, dictionaryStartLocation);
    }
    
    if (startLocation != NSNotFound) {
        jsonText = [jsonText substringFromIndex:startLocation];
    }
    
    id parsedResult = [parser objectWithString:jsonText];
    if (parsedResult) {
       if ([parsedResult isKindOfClass:[NSArray class]]) {
        outputParsedJSON.structureValue = [[QCStructure alloc] initWithArray:parsedResult];
       } else if ([parsedResult isKindOfClass:[NSDictionary class]]) {
        outputParsedJSON.structureValue = [[QCStructure alloc] initWithDictionary:parsedResult];
       }
    } else {
        outputParsedJSON.structureValue = nil;
    }
    
    outputDoneSignal.booleanValue = YES;
    return;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
    [NSThread detachNewThreadSelector:@selector(_execute:) toTarget:self withObject:self];
    return YES;
}

@end
