/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "DHImageAtURLPatch.h"
#import "NSArray+FBAdditions.h"
#import "NSURL+FBAdditions.h"
#import "QCPatch+FBAdditions.h"
#import "NSDocument+FBAdditions.h"

@interface DHImageAtURLPatch (Private)
- (void)_downloadImageAtURL:(NSString *)URL;
- (void)_updateOutputPorts;
@end

@implementation DHImageAtURLPatch

static NSMutableDictionary *_downloadedImages;

- (id)initWithIdentifier:(id)identifier {
	if (self = [super initWithIdentifier:identifier]) {
        inputUseCache.booleanValue = YES;
        _stillDownloading = [[NSMutableSet alloc] init];
        if (!_downloadedImages) {
            _downloadedImages = [[NSMutableDictionary alloc] init];
        }
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
	return kQCPatchTimeModeNone;
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
    if (!(inputURLOrURLs.wasUpdated || inputUseCache.wasUpdated)) {
        return YES;
    }
    
    id inputValue = inputURLOrURLs.rawValue;
    if ([inputValue isKindOfClass:[NSString class]]) {
        _URLs = @{@(0): inputValue};
    } else if ([inputValue isKindOfClass:[QCStructure class]]) {
        _URLs = [inputValue dictionaryRepresentation];
    } else {
        _URLs = @{};
    }
        
    [_stillDownloading removeAllObjects];
    [self _updateOutputPorts];
    
    for (id key in _URLs) {
        NSString *URL = _URLs[key];
        if (URL && (inputUseCache.booleanValue == NO || _downloadedImages[URL] == nil)) {
            [_stillDownloading addObject:URL];
            [NSThread detachNewThreadSelector:@selector(_downloadImageAtURL:) toTarget:self withObject:URL];
        }
    }
    
    return YES;
}

@end

@implementation DHImageAtURLPatch (Private)

- (void)_downloadImageAtURL:(NSString *)URL {
    if (!(URL && [URL isKindOfClass:[NSString class]])) {
        return;
    }
    
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithQuartzComposerLocation:URL relativeToDocument:self.fb_document]];
    _downloadedImages[URL] = image ? image : [NSNull null];
    [_stillDownloading removeObject:URL];
    
    [self performSelectorOnMainThread:@selector(_updateOutputPorts) withObject:nil waitUntilDone:NO];
}

- (void)_updateOutputPorts {
    if (_URLs.count == 1) {
        id result = _downloadedImages[[_URLs allValues][0]];
        outputImageOrStructure.rawValue = (result && result != [NSNull null]) ? result : nil;
        outputDone.booleanValue = YES;
        return;
    }
    
    NSMutableDictionary *images = [[NSMutableDictionary alloc] initWithCapacity:_URLs.count];
    if (_downloadedImages.count) {
        for (id key in _URLs) {
            NSString *URL = _URLs[key];
            if (![_stillDownloading containsObject:URL]) {
                NSImage *image = _downloadedImages[URL];
                if (image) {
                    images[key] = image;
                }
            }
        }
    }
  
    BOOL allKeysAreNumbers = YES;
    for (id key in images) {
        allKeysAreNumbers &= [key isKindOfClass:[NSNumber class]];
    }
  
    QCStructure *outputStructure = nil;
    if (images.count) {
        if (!allKeysAreNumbers) {
            outputStructure = [[QCStructure alloc] initWithDictionary:images];
        } else {
            NSMutableArray *sortedImages = [[NSMutableArray alloc] initWithCapacity:images.count];
            id keysArray = [[images allKeys] sortedArrayUsingAlphabeticalSort];
            for (NSNumber *key in keysArray) {
                [sortedImages addObject:images[key]];
            }
            outputStructure = [[QCStructure alloc] initWithArray:sortedImages];
        }
    }
  
    outputImageOrStructure.rawValue = outputStructure;
    outputDone.booleanValue = images.count ? (images.count == _URLs.count) : NO;
}

@end
