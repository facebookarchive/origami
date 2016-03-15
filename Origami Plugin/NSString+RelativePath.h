//
//  NSString+RelativePath.h
//
//  Created by numata on 2010/01/12.
//  Copyright 2010 Satoshi Numata. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (RelativePath)

- (NSString *)absolutePathFromBaseDirPath:(NSString *)baseDirPath;
- (NSString *)relativePathFromBaseDirPath:(NSString *)baseDirPath;

@end


