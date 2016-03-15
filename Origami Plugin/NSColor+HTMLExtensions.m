//
//  NSColor+HTMLExtensions.m
//  DHTools
//
//  Created by Drew Hamlin on 4/18/13.
//
//

#import "NSColor+HTMLExtensions.h"

@implementation NSColor (HTMLExtensions)

+ (NSColor *)colorWithHexString:(NSString *)hexString {
    if ([hexString hasPrefix:@"#"]) {
        hexString = [hexString substringFromIndex:1];
    }
    
    BOOL shorthand = (hexString.length == 3);
    NSInteger charactersToRead = shorthand ? 1: 2;
    
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:3];
    NSInteger start = 0;
    while (start < hexString.length) {
        NSString *substring = [hexString substringWithRange:NSMakeRange(start, charactersToRead)];
        if (shorthand) {
            substring = [substring stringByAppendingString:substring];
        }
        NSScanner *substringScanner = [NSScanner scannerWithString:substring];
        unsigned int result;
        [substringScanner scanHexInt:&result];
        [values addObject:@(result)];
        start += charactersToRead;
    }
    
    if (values.count < 3) {
        return [NSColor whiteColor];
    }
    
    CGFloat red = [[values objectAtIndex:0] doubleValue], green = [[values objectAtIndex:1] doubleValue], blue = [[values objectAtIndex:2] doubleValue];
    NSColor *color = [NSColor colorWithCalibratedRed:(red / 255.0) green:(green / 255.0) blue:(blue / 255.0) alpha:1.0];
    return color;
}

- (NSString *)hexStringRepresentation {
    NSColor *rgb = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    CGFloat redf, greenf, bluef, alphaf;
    [rgb getRed:&redf green:&greenf blue:&bluef alpha:&alphaf];
    int red = (int)round(redf * 255), green = (int)round(greenf * 255), blue = (int)round(bluef * 255);
    NSString *alpha = [NSString stringWithFormat:@"%.2f", alphaf];
    
	if (NO && (1.0 - alphaf) >= 0.000001) {
        return [NSString stringWithFormat:@"rgba(%d, %d, %d, %@)", red, green, blue, alpha];
        
    } else {
        NSArray *intValues = @[@(red), @(green), @(blue)];
        NSMutableArray *hexValues = [NSMutableArray arrayWithCapacity:3];
        NSMutableArray *shorthandHexValues = [NSMutableArray arrayWithCapacity:3];
        
        BOOL shorthand = YES;
        for (NSNumber *value in intValues) {
            NSString *hex = [NSString stringWithFormat:@"%02x", [value intValue]];
            shorthand &= [hex characterAtIndex:0] == [hex characterAtIndex:1];
            [hexValues addObject:hex];
            [shorthandHexValues addObject:[hex substringToIndex:1]];
        }
        
        id values = !shorthand ? hexValues : shorthandHexValues;
        return [NSString stringWithFormat:@"#%@%@%@", [values objectAtIndex:0], [values objectAtIndex:1], [values objectAtIndex:2]];
    }
}

@end
