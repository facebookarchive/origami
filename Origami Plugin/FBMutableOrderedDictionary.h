/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <Foundation/Foundation.h>

@interface FBMutableOrderedDictionary : NSObject

- (id)objectForKey:(id)key;
- (void)setObject:(id)object forKey:(id)aKey;
- (void)removeAllObjects;
- (void)removeObject:(id)object forKey:(id)aKey;
- (NSUInteger)count;
- (NSArray *)allKeys;
- (NSArray *)allValues;
- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level;
- (NSString *)descriptionWithLocale:(id)locale;
- (NSString *)description;

@end
