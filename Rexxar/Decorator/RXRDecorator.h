//
//  RXRDecorator.h
//  Rexxar
//
//  Created by GUO Lin on 5/17/16.
//  Copyright © 2016 Douban Inc. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 * `RXRDecorator` 是一个请求装修器协议。请求装修器代表了一个可用于修改 http 请求的类的协议。
 * 符合该协议的类可以用于修改 Rexxar-Container 内发出的 Http 请求。
 */
@protocol RXRDecorator <NSObject>

/**
 * 判断是否应该拦截侦听该请求
 *
 * @param request 对应请求
 */
- (BOOL)shouldInterceptRequest:(NSURLRequest *)request;

/**
 * 对该请求的修改动作
 *
 * @param request 对应请求
 */
- (void)decorateRequest:(NSMutableURLRequest *)request;


@optional

/**
 * 准备执行对该请求的修改动作
 *
 * @param request 对应请求
 */
- (void)prepareWithRequest:(NSURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
