/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "FBMutableOrderedDictionary.h"

NSString *DescriptionForObject(NSObject *object, id locale, NSUInteger indent)
{
	NSString *objectString;
	if ([object isKindOfClass:[NSString class]])
	{
		objectString = [(NSString *)object copy];
	}
	else if ([object respondsToSelector:@selector(descriptionWithLocale:indent:)])
	{
		objectString = [(NSDictionary *)object descriptionWithLocale:locale indent:indent];
	}
	else if ([object respondsToSelector:@selector(descriptionWithLocale:)])
	{
		objectString = [(NSSet *)object descriptionWithLocale:locale];
	}
	else
	{
		objectString = [object description];
	}
	return objectString;
}

@implementation FBMutableOrderedDictionary {
  NSMutableDictionary *_dictionary;
  NSMutableArray *_array;
}

- (id)init {
  if (self = [super init]) {
    _dictionary = [[NSMutableDictionary alloc] init];
    _array = [[NSMutableArray alloc] init];
  }
  return self;
}

- (id)objectForKey:(id)key {
  return [_dictionary objectForKey:key];
}

- (void)setObject:(id)object forKey:(id)aKey {
  if (object != nil && aKey != nil) {
    if (![_dictionary objectForKey:aKey]) {
      [_array addObject:aKey];
    }
    
    [_dictionary setObject:object forKey:aKey];
  }
}

- (void)removeAllObjects {
  [_dictionary removeAllObjects];
  [_array removeAllObjects];
}

- (void)removeObject:(id)object forKey:(id)aKey {
  [_dictionary removeObjectForKey:aKey];
  [_array removeObject:aKey];
}

- (NSUInteger)count {
  return [_dictionary count];
}

- (NSArray *)allKeys {
  return _array;
}

- (NSArray *)allValues {
  NSMutableArray *allValues = [NSMutableArray array];
  
  for (id key in _array) {
    if ([_dictionary objectForKey:key]) {
      [allValues addObject:[_dictionary objectForKey:key]];
    }
  }
  
  return [NSArray arrayWithArray:allValues];
}

- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level
{
	NSMutableString *indentString = [NSMutableString string];
	NSUInteger i, count = level;
	for (i = 0; i < count; i++)
	{
		[indentString appendFormat:@"    "];
	}
	
	NSMutableString *description = [NSMutableString string];
	[description appendFormat:@"%@{\n", indentString];
	for (NSObject *key in self.allKeys)
	{
		[description appendFormat:@"%@    %@ = %@;\n",
     indentString,
     DescriptionForObject(key, locale, level),
     DescriptionForObject([self objectForKey:key], locale, level)];
	}
	[description appendFormat:@"%@}\n", indentString];
	return description;
}

- (NSString *)descriptionWithLocale:(id)locale {
  return [self descriptionWithLocale:locale indent:1];
}

- (NSString *)description {
  return [self descriptionWithLocale:[NSLocale systemLocale]];
}

@end
