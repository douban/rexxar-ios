//
//  RXRURLSessionDemux.h
//  Rexxar
//
//  Created by XueMing on 31/03/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 实现 url protocol session 共享，确保每个 url protocol client 触发和回调在同一个线程里。
 */
@interface RXRURLSessionDemux : NSObject

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration;

@property (nonatomic, copy,   readonly) NSURLSessionConfiguration *sessionConfiguration;
@property (nonatomic, strong, readonly) NSURLSession *session;

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                                     delegate:(id<NSURLSessionDataDelegate>)delegate
                                        modes:(nullable NSArray *)modes;

- (void)performBlockWithTask:(NSURLSessionTask *)task
                       block:(dispatch_block_t)block;

@end

NS_ASSUME_NONNULL_END
