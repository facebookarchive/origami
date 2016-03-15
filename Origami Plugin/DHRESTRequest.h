/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <Foundation/Foundation.h>

static NSString *DHRESTRequestTypeCreate  = @"POST";
static NSString *DHRESTRequestTypeRead    = @"GET";
static NSString *DHRESTRequestTypeUpdate  = @"PUT";
static NSString *DHRESTRequestTypeDestroy = @"DELETE";

@interface DHRESTRequest : NSObject

+ (id)createObject:(id)object atURL:(NSURL *)URL;
+ (id)readObjectAtURL:(NSURL *)URL;
+ (id)updateObjectWith:(id)objectChanges atURL:(NSURL *)URL;
+ (id)destroyObjectAtURL:(NSURL *)URL;

+ (id)resultOfRequestType:(NSString *)requestType withObject:(id)object toURL:(NSURL *)URL;
+ (id)resultOfRequestType:(NSString *)requestType withObject:(id)object toURL:(NSURL *)URL withParameters:(NSDictionary *)parameters headers:(NSDictionary *)headers;

@end
