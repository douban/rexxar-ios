//
//  RXRDataValidator.h
//  Rexxar
//
//  Created by bigyelow on 06/11/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

#ifndef RXRDataValidator_h
#define RXRDataValidator_h

@protocol RXRDataValidator<NSObject>

/// Downloading HTML fils related validation.
- (BOOL)validateRemoteHTMLFile:(nullable NSURL *)fileURL fileData:(nullable NSData *)fileData;
- (BOOL)stopDownloadingIfValidationFailed;

@end


#endif /* RXRDataValidator_h */
