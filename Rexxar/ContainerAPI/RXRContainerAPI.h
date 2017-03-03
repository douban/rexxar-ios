//
//  RXRContainerAPI.h
//  Rexxar
//
//  Created by GUO Lin on 5/17/16.
//  Copyright © 2016 Douban Inc. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 * `RXRContainerAPI` 是一个请求模拟器协议。请求模拟器代表了一个可用于模拟 http 请求的类的协议。
 * 符合该协议的类可以用于模拟 Rexxar-Container 内发出的 Http 请求。
 */
@protocol RXRContainerAPI <NSObject>

/**
 * 判断是否应该截获该请求，对该请求做模拟操作。
 */
- (BOOL)shouldInterceptRequest:(NSURLRequest *)request;

/**
 * 模拟请求的返回，返回 NSURLResponse 对象。
 */
- (NSURLResponse *)responseWithRequest:(NSURLRequest *)request;

/**
 * 模拟请求返回的内容，返回二进制数据。
 */
- (nullable NSData *)responseData;

@optional

/**
 * 准备对请求的模拟。
 *
 * @param request 对应的请求
 */
- (void)prepareWithRequest:(NSURLRequest *)request;

/**
 * 执行对请求的模拟。
 *
 * @param request 对应的请求
 */
- (void)performWithRequest:(NSURLRequest *)request;

@end

NS_ASSUME_NONNULL_END

