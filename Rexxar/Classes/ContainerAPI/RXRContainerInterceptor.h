//
//  RXRContainerInterceptor.h
//  Rexxar
//
//  Created by GUO Lin on 5/17/16.
//  Copyright © 2016 Douban Inc. All rights reserved.
//

@import Foundation;

#import "RXRNSURLProtocol.h"

@protocol RXRContainerAPI;

NS_ASSUME_NONNULL_BEGIN

/**
 * `RXRContainerInterceptor` 是一个 Rexxar-Container 的请求侦听器。
 * 这个侦听器用于模拟网络请求。这些网络请求并不会发送出去，而是由 Native 处理。
 * 比如向 Web 提供当前位置信息。
 *
 */
@interface RXRContainerInterceptor : RXRNSURLProtocol

/**
 这个侦听器所有的请求模仿器数组，该数组成员是符合 `RXRContainerAPI` 协议的对象，即一组请求模仿器。
 */
@property (class, nonatomic, copy, nullable) NSArray<id<RXRContainerAPI>> *containerAPIs;

@end

NS_ASSUME_NONNULL_END
