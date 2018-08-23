//
//  RXRRequestInterceptor.h
//  Rexxar
//
//  Created by bigyelow on 09/03/2017.
//  Copyright © 2017 Douban.Inc. All rights reserved.
//

#import "RXRNSURLProtocol.h"
#import "RXRDecorator.h"

/**
 * `RXRRequestInterceptor` 是一个 Rexxar-Container 的请求侦听器。
 * 这个侦听器用于修改请求，比如增添请求的 url 参数，添加自定义的 http header。
 *
 */
@interface RXRRequestInterceptor : RXRNSURLProtocol

@property (class, nonatomic, copy, nullable) NSArray<id<RXRDecorator>> *decorators;

@end
