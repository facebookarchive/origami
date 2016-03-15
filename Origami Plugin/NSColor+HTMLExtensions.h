//
//  NSColor+HTMLExtensions.h
//  DHTools
//
//  Created by Drew Hamlin on 4/18/13.
//
//

#import <Foundation/Foundation.h>

@interface NSColor (HTMLExtensions)

+ (NSColor *)colorWithHexString:(NSString *)hexString;
- (NSString *)hexStringRepresentation;

@end
