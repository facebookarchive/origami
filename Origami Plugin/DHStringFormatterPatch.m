/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "DHStringFormatterPatch.h"
#import "NSColor+HTMLExtensions.h"

@implementation DHStringFormatterPatch

- (id)initWithIdentifier:(id)identifier {
	if (self = [super initWithIdentifier:identifier]) {
        
    }
    
	return self;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)identifier {
	return kQCPatchExecutionModeProcessor;
}

+ (BOOL)allowsSubpatchesWithIdentifier:(id)identifier {
	return NO;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)identifier {
	return kQCPatchTimeModeIdle;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
    if (!(inputString.wasUpdated ||
          inputColor.wasUpdated ||
          inputFontName.wasUpdated ||
          inputFontSize.wasUpdated ||
          inputBold.wasUpdated ||
          inputUnderline.wasUpdated ||
          inputStrikethrough.wasUpdated ||
          inputMaxWidth.wasUpdated ||
          inputMaxHeight.wasUpdated)) {
        return YES;
    }
    
    NSString *output = inputString.stringValue;
    
    if (!output.length) {
        outputFormattedString.stringValue = @"";
        return YES;
    }
    
    // Escape existing "tags"
    output = [output stringByReplacingOccurrencesOfString:@"<" withString:@"\\<"];
    
    if (inputStrikethrough.booleanValue) {
        output = [NSString stringWithFormat:@"<s>%@</s>", output];
    }
    
    if (inputUnderline.booleanValue) {
        output = [NSString stringWithFormat:@"<u>%@</u>", output];
    }
    
    if (inputBold.booleanValue) {
        output = [NSString stringWithFormat:@"<b>%@</b>", output];
    }
    
    if (inputFontSize.doubleValue) {
        output = [NSString stringWithFormat:@"<size=\"%d\">%@", (int)inputFontSize.doubleValue, output];
    }
    
    if (inputFontName.stringValue.length) {
        output = [NSString stringWithFormat:@"<font=\"%@\">%@", inputFontName.stringValue, output];
    }
    
    NSColor *defaultColor = [[NSColor whiteColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    if (inputColor.value && !([inputColor.value isEqualTo:defaultColor])) {
        CGFloat red, green, blue, alpha;
        [inputColor getRed:&red green:&green blue:&blue alpha:&alpha];
        NSColor *color = [NSColor colorWithDeviceRed:red green:green blue:blue alpha:alpha];
        NSString *textualColorRepresentation = [color hexStringRepresentation];
        
        if (textualColorRepresentation) {
            output = [NSString stringWithFormat:@"<color=\"%@\">%@", textualColorRepresentation, output];
        }
    }
    
    if (inputMaxHeight.doubleValue) {
        output = [NSString stringWithFormat:@"<height=\"%d\">%@", (int)inputMaxHeight.doubleValue, output];
    }
    
    if (inputMaxWidth.doubleValue) {
        output = [NSString stringWithFormat:@"<width=\"%d\">%@", (int)inputMaxWidth.doubleValue, output];
    }
    
    outputFormattedString.stringValue = output;
    
    return YES;
}

@end
