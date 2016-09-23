//
//  RXRNSURLProtocol.h
//  Rexxar
//
//  Created by GUO Lin on 5/17/16.
//  Copyright © 2016 Douban Inc. All rights reserved.
//

@import Foundation;

@interface RXRNSURLProtocol : NSURLProtocol

@property (nonatomic, strong) NSURLConnection *connection;

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

@end
