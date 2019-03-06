//
//  RXRProxy.h
//  Rexxar
//
//  Created by XueMing on 2019/3/5.
//  Copyright © 2019 Douban Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 本地服务代理，请求可以被代理时，从本地返回数据，否则继续发送原来的请求
 */
@protocol RXRProxy <NSObject>

/**
 * 判断是否应该拦截侦听该请求
 *
 * @param request 对应请求
 */
- (BOOL)shouldInterceptRequest:(NSURLRequest *)request;

/**
 * 当可以代理请求时，返回 NSURLResponse 对象；不能代理时返回空。
 */
- (nullable NSURLResponse *)responseWithRequest:(NSURLRequest *)request;

/**
 * 当可以代理请求是，返回代理内容；不能代理时返回空。
 */
- (nullable NSData *)responseDataWithRequest:(NSURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
