//
//  NSURLResponse+Rexxar.h
//  Rexxar
//
//  Created by XueMing on 02/03/2017.
//  Copyright © 2017 Douban.Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLResponse (Rexxar)

/**
 Returns a new http response with header-field `Access-Control-Allow-Origin`
 setting to `*`.
 */
+ (instancetype)rxr_noAccessControlHeaderInstanceForRequest:(NSURLRequest *)request;

+ (instancetype)rxr_noAccessControlHeaderInstanceWithResponse:(NSURLResponse *)response;

@end

NS_ASSUME_NONNULL_END
