/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "DHSoundPlayerProPatch.h"
#import "QCPatch+FBAdditions.h"
#import "NSURL+FBAdditions.h"

@implementation DHSoundPlayerProPatch

- (id)initWithIdentifier:(id)identifier {
	if (self = [super initWithIdentifier:identifier]) {
        inputVolume.minDoubleValue = 0;
        inputVolume.maxDoubleValue = 1;
        inputVolume.doubleValue = 1;
        
        _movieView = [[QTMovieView alloc] init];
    }
    
	return self;
}

+ (QCPatchExecutionMode)executionModeWithIdentifier:(id)identifier {
	return kQCPatchExecutionModeConsumer;
}

+ (BOOL)allowsSubpatchesWithIdentifier:(id)identifier {
	return NO;
}

+ (QCPatchTimeMode)timeModeWithIdentifier:(id)identifier {
	return kQCPatchTimeModeNone;
}

- (void)disable:(QCOpenGLContext*)context {
    [_movieView setMovie:nil];
}

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments {
    if (!(inputSoundLocation.wasUpdated || inputPlaySound.wasUpdated || inputResetSignal.wasUpdated || inputLooping.wasUpdated || inputVolume.wasUpdated)) {
        return YES;
    }
  
    if (inputSoundLocation.wasUpdated || ![_movieView movie]) {
        NSURL *soundLocationURL = [NSURL URLWithQuartzComposerLocation:inputSoundLocation.stringValue relativeToDocument:self.fb_document];

        NSError *error;
        [_movieView setMovie:[QTMovie movieWithURL:soundLocationURL error:&error]];
    }
    
    QTMovie *movie = [_movieView movie];
    [movie setAttribute:@(inputLooping.booleanValue) forKey:QTMovieLoopsAttribute];
    [movie setVolume:inputVolume.doubleValue];
    
    if (inputResetSignal.booleanValue) {
        [movie gotoBeginning];
    }
    
    if (inputPlaySound.booleanValue) {
        [_movieView play:self];
    } else {
        [_movieView pause:self];
    }
    
    return YES;
}

@end
