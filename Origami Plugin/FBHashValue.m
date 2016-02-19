//
//  HashValue.m
//  Hashing
//
//  Created by Matt Gallagher on 2009/07/06.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "FBHashValue.h"

@implementation FBHashValue

- (id)initWithBuffer:(const void *)buffer hashValueType:(FBHashValueType)aType
{
	self = [super init];
	if (self != nil)
	{
		if (aType == HASH_VALUE_MD5_TYPE)
		{
			memcpy(value, buffer, sizeof(FBHashValueMD5Hash));
		}
		else if (aType == HASH_VALUE_SHA_TYPE)
		{
			memcpy(value, buffer, sizeof(FBHashValueShaHash));
		}
		type = aType;
	}
	return self;
}

- (id)initHashValueMD5HashWithBytes:(const void *)bytes length:(NSUInteger)length
{
	self = [super init];
	if (self != nil)
	{
		CC_MD5(bytes, length, value);
		type = HASH_VALUE_MD5_TYPE;
	}
	return self;
}

+ (FBHashValue *)md5HashWithData:(NSData *)data
{
	return [[[FBHashValue alloc]
		initHashValueMD5HashWithBytes:[data bytes]
		length:[data length]]
	autorelease];
}

- (id)initSha256HashWithBytes:(const void *)bytes length:(NSUInteger)length
{
	self = [super init];
	if (self != nil)
	{
		CC_SHA256(bytes, length, value);
		type = HASH_VALUE_SHA_TYPE;
	}
	return self;
}

+ (FBHashValue *)sha256HashWithData:(NSData *)data
{
	return [[[FBHashValue alloc]
		initSha256HashWithBytes:[data bytes]
		length:[data length]]
	autorelease];
}

- (NSString *)description
{
	NSInteger byteLength;
	if (type == HASH_VALUE_MD5_TYPE)
	{
		byteLength = sizeof(FBHashValueMD5Hash);
	}
	else if (type == HASH_VALUE_SHA_TYPE)
	{
		byteLength = sizeof(FBHashValueShaHash);
	}

	NSMutableString *stringValue =
		[NSMutableString stringWithCapacity:byteLength * 2];
	NSInteger i;
	for (i = 0; i < byteLength; i++)
	{
		[stringValue appendFormat:@"%02x", value[i]];
	}
	
	return stringValue;
}

- (NSUInteger)hash
{
	return *((NSUInteger *)value);
}

- (const void *)value
{
	return value;
}

- (FBHashValueType)type
{
	return type;
}

- (BOOL)isEqual:(id)other
{
	if ([other isKindOfClass:[FBHashValue class]] &&
		((FBHashValue *)other)->type == type &&
		memcmp(((FBHashValue *)other)->value, value, HASH_VALUE_STORAGE_SIZE) == 0)
	{
		return YES;
	}
	
	return NO;
}

- (id)copyWithZone:(NSZone *)zone
{
	return [[[self class] allocWithZone:zone] initWithBuffer:value hashValueType:type];
}

- (id)initWithCoder:(NSCoder *)aCoder
{
	self = [super init];
	if (self != nil)
	{
		NSData *valueData = [aCoder decodeObjectForKey:@"value"];
		memcpy(value, [valueData bytes], [valueData length]);
		[valueData self];
		
		type = [aCoder decodeIntForKey:@"type"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder
		encodeObject:[NSData dataWithBytes:value length:HASH_VALUE_STORAGE_SIZE]
		forKey:@"value"];
	[encoder encodeInt:type forKey:@"type"];
}

- (NSString *)stringValue {
  return [self description];
}

@end
