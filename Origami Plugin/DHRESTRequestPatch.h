/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import <SkankySDK/SkankySDK.h>

@interface DHRESTRequestPatch : QCPatch
{
    QCBooleanPort *inputEnable;
    QCIndexPort *inputRequestType;
    QCStringPort *inputURL;
    QCStructurePort *inputParameters;
    QCStructurePort *inputHeaders;
    QCVirtualPort *inputObject;
    QCBooleanPort *inputUpdateSignal;
    QCVirtualPort *outputResult;
    QCBooleanPort *outputDoneSignal;
    
    BOOL _debug;
}

@end
