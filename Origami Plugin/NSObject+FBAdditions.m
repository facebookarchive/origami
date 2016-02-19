/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "NSObject+FBAdditions.h"

@implementation NSObject (FBAdditions)

- (void)fb_swizzleInstanceMethod:(SEL)method forClassName:(NSString *)className {
  Class class = NSClassFromString(className);
  NSString *methodString = NSStringFromSelector(method);
  SEL replacement = NSSelectorFromString([NSString stringWithFormat:@"original_%@",methodString]);
  
  Method m0 = class_getInstanceMethod([self class], method);
	class_addMethod(class, replacement, method_getImplementation(m0), method_getTypeEncoding(m0));
	
	Method m1 = class_getInstanceMethod(class, method);
	Method m2 = class_getInstanceMethod(class, replacement);
	
	method_exchangeImplementations(m1, m2);
}

@end
