//
//  NSURL+Rexxar.h
//  Rexxar
//
//  Created by GUO Lin on 1/18/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

@import Foundation;

@interface NSURL (Rexxar)

/**
 * 将一个字典内容转换成 url 的 query 的形式。
 *
 * @param dict 需要转换成的 query 的 dictionary。
 */
+ (NSString *)rxr_queryFromDictionary:(NSDictionary *)dict;

/**
 * 该 url 的 scheme 是否是 http 或 https？
 */
- (BOOL)rxr_isHttpOrHttps;

/**
 * 将该 url 的 query 以字典形式返回。
 */
- (NSDictionary *)rxr_queryDictionary;

/**
* 该 url 的 scheme 是否是 rexxar-http 或 rexxar-https
*/
- (BOOL)rxr_isRexxarHttpScheme;

/**
* 将该 url 的 scheme 从 rexxar-http, rexxar-https 替换为 http, https。
*/
- (NSURL *)rxr_urlByRemovingRexxarScheme;

/**
* 将该 url 的 scheme 从 http, https 替换为 rexxar-http, rexxar-https。
*/
- (NSURL *)rxr_urlByAddingRexxarScheme;

@end
