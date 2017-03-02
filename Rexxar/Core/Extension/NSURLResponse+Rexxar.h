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

+ (instancetype)rxr_defaultResponseForRequest:(NSURLRequest *)request;

- (instancetype)rxr_noAccessControlResponse;

@end

NS_ASSUME_NONNULL_END
