//
//  NSObject+AssociatedObjects.m
//  
//  Created by Andy Matuschak on 8/27/09.
//  Public domain because I love you.
//

#import "NSObject+AssociatedObjects.h"
#import <objc/runtime.h>

@implementation NSObject (AMAssociatedObjects)

- (void)associateValue:(id)value withKey:(void *)key
{
	objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_RETAIN);
}

- (void)weaklyAssociateValue:(id)value withKey:(void *)key
{
	objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_ASSIGN);
}

- (id)associatedValueForKey:(void *)key
{
	return objc_getAssociatedObject(self, key);
}

@end
