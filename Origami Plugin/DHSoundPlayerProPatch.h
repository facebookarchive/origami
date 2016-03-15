/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <Foundation/Foundation.h>
#import <SkankySDK/SkankySDK.h>
#import <QTKit/QTKit.h>

@interface DHSoundPlayerProPatch : QCPatch
{
    QCStringPort *inputSoundLocation;
    QCBooleanPort *inputPlaySound;
    QCBooleanPort *inputResetSignal;
    QCBooleanPort *inputLooping;
    QCNumberPort *inputVolume;
    
    QTMovieView *_movieView;
}

@end
