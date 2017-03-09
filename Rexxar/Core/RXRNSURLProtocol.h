//
//  RXRNSURLProtocol.h
//  Rexxar
//
//  Created by GUO Lin on 5/17/16.
//  Copyright © 2016 Douban Inc. All rights reserved.
//

@import Foundation;

@interface RXRNSURLProtocol : NSURLProtocol <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, readonly) NSURLSession *URLSession;
@property (nonatomic, strong) NSURLSessionTask *dataTask;


#pragma mark - Public methods, do not override
/**
 * 将该请求标记为可以忽略
 *
 * @param request
 */
+ (void)markRequestAsIgnored:(NSMutableURLRequest *)request;

/**
 * 判断该请求是否是被忽略的
 *
 * @param request
 */
+ (BOOL)isRequestIgnored:(NSURLRequest *)request;

/**
 @param clazz a subclass of `RXRURLProtocol`
 */
+ (BOOL)registerRXRProtocolClass:(Class)clazz;


/**
 @param clazz a subclass of `RXRURLProtocol`
 */
+ (void)unregisterRXRProtocolClass:(Class)clazz;

@end
