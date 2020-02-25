//
//  RXRNSURLProtocol.h
//  Rexxar
//
//  Created by GUO Lin on 5/17/16.
//  Copyright © 2016 Douban Inc. All rights reserved.
//

@import Foundation;

@class RXRURLSessionDemux;

@interface RXRNSURLProtocol : NSURLProtocol <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSessionTask *dataTask;
@property (nonatomic, copy) NSArray *modes;

#pragma mark - Public methods, do not override

/**
 * 在startLoading中调用此方法
 */
- (void)beforeStartLoadingRequest;

/**
 * 加载完成时调用此方法
 */
- (void)afterStopLoadingRequest;

/**
 * 将该请求标记为可以忽略
 */
+ (void)markRequestAsIgnored:(NSMutableURLRequest *)request;

/**
 * 清除该请求 `可忽略` 标识
 */
+ (void)unmarkRequestAsIgnored:(NSMutableURLRequest *)request;

/**
 * 判断该请求是否是被忽略的
 */
+ (BOOL)isRequestIgnored:(NSURLRequest *)request;

/**
 * 注册 `RXRURLProtocol`
 *
 * @param clazz a subclass of `RXRURLProtocol`
 */
+ (BOOL)registerRXRProtocolClass:(Class)clazz;

/**
 * 反注册 `RXRURLProtocol`
 *
 * @param clazz a subclass of `RXRURLProtocol`
 */
+ (void)unregisterRXRProtocolClass:(Class)clazz;

/**
 * 实现 URLSession 共享和 URLProtocol client 回调的分发
 *
 * @return 共享的复用解析器
 */
+ (RXRURLSessionDemux *)sharedDemux;

@end

///
/// 截获所有的 http / https 请求，然后内部使用 URLSession 重新发送请求
/// 为了确保 URLProtocol 注册顺序，使用时必须优先注册这个类
///
@interface RXRDefaultURLProtocol : RXRNSURLProtocol

@end
