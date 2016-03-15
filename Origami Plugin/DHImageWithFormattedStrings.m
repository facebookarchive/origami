/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "DHImageWithFormattedStrings.h"
#import "NSString+FBAdditions.h"
#import "NSColor+HTMLExtensions.h"

@implementation DHImageWithFormattedStrings

static NSString *DHStyleColor            = @"DHStyleColor";
static NSString *DHStyleFontName         = @"DHStyleFontName";
static NSString *DHStyleFontSize         = @"DHStyleFontSize";
static NSString *DHStyleBold             = @"DHStyleBold";
static NSString *DHStyleItalic           = @"DHStyleItalic";
static NSString *DHStyleUnderline        = @"DHStyleUnderline";
static NSString *DHStyleStrikethrough    = @"DHStyleStrikethrough";
static NSString *DHStyleMaxWidth         = @"DHStyleMaxWidth";
static NSString *DHStyleMaxHeight         = @"DHStyleMaxHeight";

static NSString *DHFormattedStringTagIdentifier = @"identifier";
static NSString *DHFormattedStringTagValue      = @"value";
static NSString *DHFormattedStringTagKind       = @"kind";

typedef enum DHFormattedStringTagKinds : NSInteger {
    DHFormattedStringTagKindOpenTag,
    DHFormattedStringTagKindCloseTag
} DHFormattedStringTagKinds;

- (id)initWithIdentifier:(id)identifier {
	if (!(self = [super initWithIdentifier:identifier])) {
        return nil;
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

- (id)_style:(id)style in:(NSDictionary *)dictionary {
    id result = [dictionary objectForKey:style];
    return result ? result : @(NO);
}

- (NSDictionary *)_attributesDictionaryFromStyles:(NSDictionary *)styles {
    NSUInteger fontSize = [[self _style:DHStyleFontSize in:styles] integerValue];
    NSFont *font = [NSFont fontWithName: [self _style:DHStyleFontName in:styles]
                                   size:fontSize];
    
    if (!font) {
        font = [NSFont fontWithName:@"Helvetica" size:fontSize];
    }
    
    if ([[self _style:DHStyleBold in:styles] boolValue] == YES) {
        NSFontManager *fontManager = [NSFontManager sharedFontManager];
        font = [fontManager convertFont:font toHaveTrait:NSBoldFontMask];
    }
    
    return @{
        NSFontAttributeName:               font,
        NSForegroundColorAttributeName:    [self _style:DHStyleColor in:styles],
        NSUnderlineStyleAttributeName:     [self _style:DHStyleUnderline in:styles],
        NSStrikethroughStyleAttributeName: [self _style:DHStyleStrikethrough in:styles],
    };
}

- (NSImage *)_imageFromAttributedString:(NSAttributedString *)attributedString withMaxSize:(NSSize)maxSize {
    
    NSSize size = [attributedString size];
    if (!(size.width && size.height)) {
        return nil;
    }
    
    BOOL constrainWidth = ([@(maxSize.width) integerValue]) ? YES : NO;
    BOOL constrainHeight = ([@(maxSize.height) integerValue]) ? YES : NO;
    
    CGFloat imageWidth = constrainWidth ? maxSize.width : size.width;

    NSStringDrawingOptions stringDrawingOptions = (NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading | NSStringDrawingTruncatesLastVisibleLine);
    
    NSRect boundingRect = [attributedString boundingRectWithSize:CGSizeMake(imageWidth, CGFLOAT_MAX) options:stringDrawingOptions];
    if (constrainWidth) {
        boundingRect.size.width = maxSize.width;
    }
    if (constrainHeight) {
        boundingRect.size.height = MIN(boundingRect.size.height, maxSize.height);
    }
    
    NSImage *image = [[NSImage alloc] initWithSize:boundingRect.size];
    [image lockFocus];
    {
        [attributedString drawWithRect:boundingRect options:stringDrawingOptions];
    }
    [image unlockFocus];
    
    return image;
}

- (NSDictionary *)_informationForTag:(NSString *)tag {
    BOOL isCloseTag = [tag hasPrefix:@"/"];
    if (isCloseTag && tag.length > 1) {
        tag = [tag substringFromIndex:1];
    }
    
    NSArray *components = [tag componentsSeparatedByUnescapedDelimeter:@"="];
    NSString *tagIdentifier = components.count > 0 ? [components objectAtIndex:0] : @"";
    NSString *tagValue = components.count > 1 ? [components objectAtIndex:1] : @"";
    
    // Trim whitespace
    tagIdentifier = [tagIdentifier stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    tagValue = [tagValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // Remove proceeding and trailing quotes
    if ([tagValue hasPrefix:@"\""] && tag.length > 1) {
        tagValue = [tagValue substringFromIndex:1];
    }
    if ([tagValue hasSuffix:@"\""] && tag.length > 1) {
        tagValue = [tagValue substringToIndex:tagValue.length - 1];
    }
    
    return @{DHFormattedStringTagIdentifier: tagIdentifier,
             DHFormattedStringTagValue: tagValue,
             DHFormattedStringTagKind : isCloseTag ? @(DHFormattedStringTagKindCloseTag) : @(DHFormattedStringTagKindOpenTag)};
}


- (void)_applyTag:(NSString *)tag toStyles:(NSMutableDictionary **)styles {
    if (!styles) {
        return;
    }
    
    NSDictionary *tagInformation = [self _informationForTag:tag];
    
    NSString *tagIdentifier = tagInformation[DHFormattedStringTagIdentifier];
    NSString *tagValue = tagInformation[DHFormattedStringTagValue];
    
    DHFormattedStringTagKinds tagKind = [tagInformation[DHFormattedStringTagKind] integerValue];
    BOOL isCloseTag = (tagKind == DHFormattedStringTagKindCloseTag) ? YES : NO;
    
    NSDictionary *styleTermonologyDictionary = @{
        @"b":      DHStyleBold,
        @"i":      DHStyleItalic,
        @"u":      DHStyleUnderline,
        @"s":      DHStyleStrikethrough,
        @"color":  DHStyleColor,
        @"font":   DHStyleFontName,
        @"size":   DHStyleFontSize,
        @"width":  DHStyleMaxWidth,
        @"height": DHStyleMaxHeight
    };
    
    NSString *styleKey = styleTermonologyDictionary[tagIdentifier];
    id styleValue = tagValue;
    
    if ([styleKey isEqualToString:DHStyleColor]) {
        styleValue = [NSColor colorWithHexString:tagValue];
    } else if ([styleKey isEqualToString:DHStyleBold] ||
               [styleKey isEqualToString:DHStyleItalic] ||
               [styleKey isEqualToString:DHStyleUnderline] ||
               [styleKey isEqualToString:DHStyleStrikethrough]) {
        styleValue = isCloseTag ? @(NO) : @(YES);
    }
    
    if (styleKey) {
        [*styles setObject:styleValue forKey:styleKey];
    }
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
    if (!inputString.wasUpdated) {
        return YES;
    }
    
    NSMutableDictionary *currentStyles =
    [@{
      DHStyleColor: [NSColor whiteColor],
      DHStyleFontName: @"Helvetica",
      DHStyleFontSize: @20,
      DHStyleBold: @(NO),
      DHStyleUnderline: @(NO),
      DHStyleStrikethrough: @(NO),
      DHStyleMaxWidth: @0,
      DHStyleMaxHeight: @0
    } mutableCopy];
    
    NSMutableDictionary *rangedStylesDictionary = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *openTags = [NSMutableDictionary dictionary];
    
    NSString *string = inputString.stringValue;
    NSScanner *scanner = [[NSScanner alloc] initWithString:string];
    [scanner setCharactersToBeSkipped:nil];
    
    NSMutableString *unformattedBuffer = [[NSMutableString alloc] init];
    while (YES) {
        NSString *content = nil;
        [scanner scanUpToString:@"<" intoString:&content];
        if (content) {
            [unformattedBuffer appendString:content];
        }
        
        if ([scanner isAtEnd]) {
            break;
        }
        
        if ([content hasSuffix:@"\\"]) {
            [scanner scanString:@"<" intoString:NULL];
            [unformattedBuffer deleteCharactersInRange:NSMakeRange(unformattedBuffer.length - 1, 1)];
            [unformattedBuffer appendString:@"<"];
            continue;
        }
        
        NSString *tag = nil;
        [scanner scanString:@"<" intoString:NULL];
        [scanner scanUpToString:@">" intoString:&tag];
        
        NSDictionary *tagInformation = [self _informationForTag:tag];
        NSString *tagIdentifier = tagInformation[DHFormattedStringTagIdentifier];        
        BOOL isCloseTag = [tag hasPrefix:@"/"];
        
        if (isCloseTag) {            
            NSUInteger startRange = 0;
            id startRangeOfOpenTag = openTags[tagIdentifier];
            if (startRangeOfOpenTag) {
                startRange = [startRangeOfOpenTag integerValue];
                [openTags removeObjectForKey:tagIdentifier];
            }
            
            [rangedStylesDictionary setObject:[currentStyles copy] forKey:NSStringFromRange(NSMakeRange(startRange, unformattedBuffer.length - startRange))];
        } else {
            if (unformattedBuffer.length && !openTags[tagIdentifier]) {
                openTags[tagIdentifier] = @(unformattedBuffer.length);
            }
        }
        
        [self _applyTag:tag toStyles:&currentStyles];
        [scanner scanString:@">" intoString:NULL];
    };
    
    string = unformattedBuffer;
    
    NSDictionary *attributesDictionary = [self _attributesDictionaryFromStyles:currentStyles];
    NSMutableAttributedString *attributedString = [[[NSAttributedString alloc] initWithString:string attributes:attributesDictionary] mutableCopy];
    
    for (NSString *rangeKey in rangedStylesDictionary) {
        NSRange range = NSRangeFromString(rangeKey);
        NSDictionary *rangedStyles = [rangedStylesDictionary objectForKey:rangeKey];
        NSDictionary *rangedAttributes = [self _attributesDictionaryFromStyles:rangedStyles];
        [attributedString addAttributes:rangedAttributes range:range];
    }
    
    NSSize maxSize = NSMakeSize([[self _style:DHStyleMaxWidth in:currentStyles] floatValue],
                                [[self _style:DHStyleMaxHeight in:currentStyles] floatValue]);
    
    NSImage *image = [self _imageFromAttributedString:attributedString withMaxSize:maxSize];
    
    outputImage.imageValue = [[QCImage alloc] initWithNSImage:image options:0];
    outputUnformattedString.stringValue = string;
    
    return YES;
}

@end
