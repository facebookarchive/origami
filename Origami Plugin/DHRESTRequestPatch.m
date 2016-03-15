/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "DHRESTRequestPatch.h"
#import "DHRESTRequest.h"
#import "SBJson.h"

typedef enum DHRESTRequestPatchRequestType : NSInteger {
    DHRESTRequestPatchRequestTypeCreate,
    DHRESTRequestPatchRequestTypeRead,
    DHRESTRequestPatchRequestTypeUpdate,
    DHRESTRequestPatchRequestTypeDestroy,
    DHRESTRequestPatchRequestTypeCount
} DHRESTRequestPatchRequestType;

@implementation DHRESTRequestPatch

- (id)initWithIdentifier:(id)identifier {
	if (self = [super initWithIdentifier:identifier]) {
        inputRequestType.indexValue = DHRESTRequestPatchRequestTypeRead;
        inputRequestType.maxIndexValue = DHRESTRequestPatchRequestTypeCount - 1;
        
        _debug = NO;
    }
    
	return self;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)identifier {
	return kQCPatchExecutionModeProvider;
}

+ (BOOL)allowsSubpatchesWithIdentifier:(id)identifier {
	return NO;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)identifier {
	return kQCPatchTimeModeNone;
}

- (void)_execute:(id)sender {
    outputDoneSignal.booleanValue = NO;
    if (!(inputEnable.wasUpdated || inputRequestType.wasUpdated || inputURL.wasUpdated || inputObject.wasUpdated || inputHeaders.wasUpdated || (inputUpdateSignal.wasUpdated && inputUpdateSignal.booleanValue == YES))) {
        return;
    }
    
    id requestObject = inputObject.rawValue;
    if ([requestObject isKindOfClass:[QCStructure class]]) {
        requestObject = [requestObject dictionaryRepresentation];
    }
    
    NSURL *requestURL = [NSURL URLWithString:inputURL.stringValue];
    NSDictionary *parameters = [inputParameters.structureValue dictionaryRepresentation];
    NSDictionary *headers = [inputHeaders.structureValue dictionaryRepresentation];
    
    NSString *requestType = nil;
    switch (inputRequestType.indexValue) {
        case DHRESTRequestPatchRequestTypeCreate:
            requestType = DHRESTRequestTypeCreate;
            break;
        case DHRESTRequestPatchRequestTypeRead:
            requestType = DHRESTRequestTypeRead;
            break;
        case DHRESTRequestPatchRequestTypeUpdate:
            requestType = DHRESTRequestTypeUpdate;
            break;
        case DHRESTRequestPatchRequestTypeDestroy:
            requestType = DHRESTRequestTypeDestroy;
            break;
    }
    
    if (_debug) NSLog(@"%@ with %@ to %@ with %@", requestType, requestObject, requestURL, headers);
    
    id result = [DHRESTRequest resultOfRequestType:requestType withObject:requestObject toURL:requestURL withParameters:parameters headers:headers];
    
    if (_debug) NSLog(@"Result: %@", result);
    
    outputResult.rawValue = result;
    outputDoneSignal.booleanValue = YES;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
    if (inputEnable.booleanValue == NO) {
        outputResult.rawValue = nil;
        outputDoneSignal.booleanValue = NO;
        return YES;
    }
    
    [NSThread detachNewThreadSelector:@selector(_execute:) toTarget:self withObject:self];
    return YES;
}

@end
