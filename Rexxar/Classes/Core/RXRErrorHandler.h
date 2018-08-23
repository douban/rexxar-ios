//
//  RXRErrorHandler.h
//  Rexxar
//
//  Created by bigyelow on 21/12/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT const NSString * _Nonnull rxrErrorUserInfoURLKey;
FOUNDATION_EXPORT NSErrorDomain _Nonnull rxrHttpErrorDomain;
FOUNDATION_EXPORT const NSInteger rxrHttpResponseErrorNotFound;
FOUNDATION_EXPORT const NSInteger rxrHttpResponseURLProtocolError;

@protocol RXRErrorHandler <NSObject>
- (void)handleError:(nullable NSError *)error fromReporter:(nullable id)reporter;
@end
