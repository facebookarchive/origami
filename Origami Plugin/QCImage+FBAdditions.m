/*
 *  Copyright (c) 2016-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */

#import "QCImage+FBAdditions.h"
#import <CommonCrypto/CommonDigest.h>
#import "FBHashValue.h"

@implementation QCImage (FBAdditions)

- (NSString *)fb_dataMD5 {
  NSData *data = [NSArchiver archivedDataWithRootObject:self];
  
  unsigned char result[16];
  CC_MD5([data bytes], [data length], result);
  NSString *hash = [NSString stringWithFormat:
                    @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                    result[0], result[1], result[2], result[3],
                    result[4], result[5], result[6], result[7],
                    result[8], result[9], result[10], result[11],
                    result[12], result[13], result[14], result[15]
                    ];
  return hash;
}

- (NSString *)fb_providerMD5 {
  QCMD5Sum sum = [[self provider] providerMD5];
  FBHashValue *hash = [[FBHashValue alloc] initHashValueMD5HashWithBytes:sum.bytes length:16];
  return hash.stringValue;
}

- (NSData *)fb_imageData {
  NSMutableData *imageData = [NSMutableData data];
  
  QCImage *qcImage = self;
  
  CGColorSpaceRef genericRGB = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  
  id exporter = [NSClassFromString(@"QCExporter_CoreGraphics") exporterForImageManager:[QCImageManager sharedSoftwareImageManager]];
  CGImageRef image = (__bridge CGImageRef)[exporter createRepresentationOfType:@"CGImage" withProvider:[qcImage provider] transformation:[qcImage transformation] bounds:[qcImage bounds] colorSpace:genericRGB options:0];
  
  CGColorSpaceRelease(genericRGB);

  if (!image) {
    return nil;
  }
  
  if (![[qcImage provider] hasAlpha]) {
    // CGImageRef -> JPEG
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, kUTTypeJPEG, 1, NULL);
    
    CFMutableDictionaryRef properties = CFDictionaryCreateMutable(nil, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(properties, kCGImageDestinationLossyCompressionQuality, CFBridgingRetain([NSNumber numberWithFloat:0.99]));
    
    if (destination) {
      CGImageDestinationAddImage(destination, image, properties);
      CGImageRelease(image);
      CGImageDestinationFinalize(destination);
      CFRelease(destination);
    } else {
      NSLog(@"Error encoding JPEG");
    }
  } else {
    // Rasmus CGImageRef -> Tiff NSData
    size_t count = 1;
    CFStringRef outputUTType = kUTTypeTIFF;
    NSDictionary *tiffOutputProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithInt:NSTIFFCompressionLZW], (__bridge NSString*)kCGImagePropertyTIFFCompression,
                                          nil];
    
    tiffOutputProperties = nil;
    NSDictionary *outputProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                      tiffOutputProperties, (__bridge NSString*)kCGImagePropertyTIFFDictionary,
                                      //kCGImageDestinationLossyCompressionQuality, ... ,
                                      nil];
    CGImageDestinationRef idst = CGImageDestinationCreateWithData((__bridge_retained CFMutableDataRef)imageData, outputUTType, count, NULL);
    if (idst) {
      CGImageDestinationAddImage(idst, image, (__bridge_retained CFDictionaryRef)outputProperties);
      CGImageRelease(image);
      CGImageDestinationFinalize(idst); // this blocks for the duration of the computation
      CFRelease(idst);
    } else {
      NSLog(@"Error encoding TIFF");
    }
  }
  
  return [NSData dataWithData:imageData];
}

@end
