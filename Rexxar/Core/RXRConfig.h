//
//  RXRConfig.h
//  Rexxar
//
//  Created by GUO Lin on 5/30/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 * `RXRConfig` 提供对 Rexxar 的全局配置接口。
 */
@interface RXRConfig : NSObject

/**
 * 设置 rxrProtocolScheme。
 *
 * @discussion Rexxar-Container 实现了实现了一些供 Web 调用的功能。Web 调用这些功能的方式是发出一个特定的请求。
 * `rxrProtocolHost` 是对这些特定请求的 scheme 的商定。如不设置，缺省为 douban。
 */
+ (void)setRXRProtocolScheme:(NSString *)scheme;

/**
 * 设置 rxrProtocolScheme。
 *
 * @discussion Rexxar-Container 实现了实现了一些供 Web 调用的功能。Web 调用这些功能的方式是发出一个特定的请求。
 * `rxrProtocolHost` 是对这些特定请求的 scheme 的商定。如不设置，缺省为 douban。
 */
+ (NSString *)rxrProtocolScheme;

/**
 * 设置 rxrProtocolHost。
 *
 * @discussion Rexxar-Container 实现了实现了一些供 Web 调用的功能。Web 调用这些功能的方式是发出一个特定的请求。
 * `rxrProtocolHost` 是对这些特定请求的 host 的商定。如不设置，缺省为 rexxar-container。
 */
+ (void)setRXRProtocolHost:(NSString *)host;

/**
 * 读取 rxrProtocolHost。
 * 
 * @discussion Rexxar-Container 实现了实现了一些供 Web 调用的功能。Web 调用这些功能的方式是发出一个特定的请求。
 * `rxrProtocolHost` 是对这些特定请求的 host 的商定。如不设置，缺省为 rexxar-container。
 */
+ (NSString *)rxrProtocolHost;

/**
 * 设置 Routes Map URL。
 */
+ (void)setRoutesMapURL:(NSURL *)routesMapURL;

/**
 * 读取 Routes Map URL。
 */
+ (nullable NSURL *)routesMapURL;

/**
 * 设置 Route Files 的 Cache URL。
 */
+ (void)setRoutesCachePath:(nullable NSString *)routesCachePath;

/**
 * 读取 Route Files 的 Cache URL。
 */
+ (nullable NSString *)routesCachePath;

/**
 * 设置 Route Files 的 Resource Path。
 */
+ (void)setRoutesResourcePath:(nullable NSString *)routesResourcePath;

/**
 * 读取 Route Files 的 Resource Path。
 */
+ (nullable NSString *)routesResourcePath;

/**
 * 设置 Rexxar 接收的外部 User-Agent。Rexxar 会将这个 UserAgent 加到其所发出的所有的请求的 Headers 中。
 */
+ (void)setExternalUserAgent:(NSString *)userAgent;

/**
 * 读取 Rexxar 接收的外部 User-Agent。
 */
+ (NSString *)externalUserAgent;

/**
 * 更新全局配置。
 */
+ (void)updateConfig;

/**
 * 全局设置 Rexxar Container 是否使用路由文件的本地 Cache。
 * 如果使用，优先读取本地缓存的 html 文件；如果不使用，则每次都读取服务器的 html 文件。
 */
+ (void)setCacheEnable:(BOOL)isCacheEnable;

/**
 * 读取 Rexxar Container 是否使用缓存的全局配置。该缺省是打开的。Rexxar Container 会使用缓存保存 html 文件。
 */
+ (BOOL)isCacheEnable;

@end

NS_ASSUME_NONNULL_END
