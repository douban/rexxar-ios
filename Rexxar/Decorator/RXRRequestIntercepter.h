//
//  RXRRequestIntercepter.h
//  Rexxar
//
//  Created by GUO Lin on 5/17/16.
//  Copyright © 2016 Douban Inc. All rights reserved.
//

@import Foundation;

#import "RXRNSURLProtocol.h"

@protocol RXRDecorator;

NS_ASSUME_NONNULL_BEGIN

/**
 * `RXRRequestIntercepter` 是一个 Rexxar-Container 的请求侦听器。
 * 这个侦听器用于修改请求，比如增添请求的 url 参数，添加自定义的 http header。
 *
 */
@interface RXRRequestIntercepter : RXRNSURLProtocol

/**
 * 设置这个侦听器所有的请求装修器数组，该数组成员是符合 `RXRDecorator` 协议的对象，即一组请求装修器。
 * 
 * @param decorators 装修器数组
 */
+ (void)setDecorators:(NSArray<id<RXRDecorator>> *)decorators;

/**
 * 获得对应的请求装修器数组，该数组成员是符合 `RXRDecorator` 协议的对象，即一组请求装修器。
 */
+ (nullable NSArray<id<RXRDecorator>> *)decorators;

@end

NS_ASSUME_NONNULL_END