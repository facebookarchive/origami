/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "DHRESTRequest.h"
#import "Sbjson.h"

static BOOL _DHRestRequestDebug = NO;

static NSString * (^URLEncodeString)(NSString *) = ^ NSString * (NSString *string) {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8));
};

@implementation DHRESTRequest

+ (id)createObject:(id)object atURL:(NSURL *)URL {
    return [self resultOfRequestType:DHRESTRequestTypeCreate withObject:object toURL:URL];
}

+ (id)readObjectAtURL:(NSURL *)URL {
    return [self resultOfRequestType:DHRESTRequestTypeRead withObject:nil toURL:URL];
}

+ (id)updateObjectWith:(id)objectChanges atURL:(NSURL *)URL {
    return [self resultOfRequestType:DHRESTRequestTypeUpdate withObject:objectChanges toURL:URL];
}

+ (id)destroyObjectAtURL:(NSURL *)URL {
    return [self resultOfRequestType:DHRESTRequestTypeDestroy withObject:nil toURL:URL];
}

+ (id)resultOfRequestType:(NSString *)requestType withObject:(id)object toURL:(NSURL *)URL {
    return [self resultOfRequestType:requestType withObject:object toURL:URL withParameters:nil headers:nil];
}

+ (id)resultOfRequestType:(NSString *)requestType withObject:(id)object toURL:(NSURL *)URL withParameters:(NSDictionary *)parameters headers:(NSDictionary *)headers {
    SBJsonWriter *jsonWriter;
    
    NSData *jsonData = nil;
    if (object && ([requestType isEqualToString:DHRESTRequestTypeCreate] || [requestType isEqualToString:DHRESTRequestTypeUpdate])) {
        jsonWriter = [[SBJsonWriter alloc] init];
        NSString *json = ([object isKindOfClass:[NSString class]]) ? object : [jsonWriter stringWithObject:object];
        jsonData = [json dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO];
    }
    
    // Add parameters
    if (parameters && [parameters count]) {
        NSMutableArray *queryParameters = [NSMutableArray arrayWithCapacity:[parameters count]];
        [parameters enumerateKeysAndObjectsUsingBlock:^ (id key, id obj, BOOL *stop) {
            NSMutableString *parameter = [NSMutableString string];
            [parameter appendString:URLEncodeString(key)];
            [parameter appendString:@"="];
            if (![obj isKindOfClass:[NSNull class]]) {
                [parameter appendString:URLEncodeString(obj)];
            }
            [queryParameters addObject:parameter];
        }];
        NSString *parametersString = [@"?" stringByAppendingString:[queryParameters componentsJoinedByString:@"&"]];
        NSString *URLWithParametersString = [[URL absoluteString] stringByAppendingString:parametersString];
        URL = [NSURL URLWithString:URLWithParametersString];
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:URL];
    [request setHTTPMethod:requestType];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    if (headers) {
        for (id key in headers) {
            id value = headers[key];
            NSString *keyString = ([key isKindOfClass:[NSString class]]) ? key : [key description];
            [request setValue:value forHTTPHeaderField:keyString];
        }
    }
    if (jsonData) {
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:jsonData];
    }
    
    if (_DHRestRequestDebug) {
        NSLog(@"Request: %@", request);
    }
    
	NSHTTPURLResponse *response;
    NSError *error;
	NSData *resultData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (response.statusCode != 200 && response.statusCode != 201) {
        return @(NO);
    }
    if (!resultData) {
        return @(YES);
    }
    
    NSString *resultString = [[NSString alloc] initWithData:resultData encoding:NSASCIIStringEncoding];
    
    SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
    id result = [jsonParser objectWithData:resultData];
    return result ? result : resultString;
}

@end
