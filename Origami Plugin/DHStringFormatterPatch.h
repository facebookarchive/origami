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

@interface DHStringFormatterPatch : QCPatch
{
    QCStringPort *inputString;
    QCColorPort *inputColor;
    QCStringPort *inputFontName;
    QCNumberPort *inputFontSize;
    QCBooleanPort *inputBold;
    QCBooleanPort *inputUnderline;
    QCBooleanPort *inputStrikethrough;
    QCNumberPort *inputMaxWidth;
    QCNumberPort *inputMaxHeight;
    QCStringPort *outputFormattedString;
}

@end
