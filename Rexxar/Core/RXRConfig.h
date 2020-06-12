//
//  RXRConfig.h
//  Rexxar
//
//  Created by GUO Lin on 5/30/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

@import Foundation;

@protocol RXRDataValidator;
@protocol RXRLogger;
@protocol RXRErrorHandler;

NS_ASSUME_NONNULL_BEGIN

typedef void(^RXRDidCompleteRequestBlock)(NSURL *_Nonnull url, NSURLResponse *_Nullable response, NSError *_Nullable error, NSTimeInterval timeElapsed);

/**
 * `RXRConfig` 提供对 Rexxar 的全局配置接口。
 */
@interface RXRConfig : NSObject

/**
 设置 `RXRLogger`，调用者需要实现 `rexxarDidLogWithLogObject:` 方法。
 */
@property (nullable, class, nonatomic, weak) id<RXRLogger> logger;

/**
 设置 `RXRErrorHandler`，调用者需要实现 `reporter:didReceiveError:` 方法。
 */
@property (nullable, class, nonatomic, weak) id<RXRErrorHandler> errorHandler;

/**
 设置当遇到远程 html 文件找不到(http:// 地址对应的文件) 时重新加载 webview 的次数，默认为2次。

 - Note: 每一次 reload 会调用 `updateRoutesWithCompletion:` 方法更新路由及本地文件。
 */
@property (class, nonatomic) NSInteger reloadLimitWhen404;

/**
RXRRequestInterceptor处理请求完成时的回调
*/
@property (class, nonatomic, copy, nullable) RXRDidCompleteRequestBlock didCompleteRequestBlock;

/**
 使用WKURLSchemeHandler拦截网络请求，默认NO，iOS 13.4以上版本可以设置为YES
*/
@property (class, nonatomic) BOOL useCustomScheme;

/**
 * 设置 rxrProtocolScheme。
 *
 * @discussion Rexxar-Container 实现了一些供 Web 调用的功能。Web 调用这些功能的方式是发出一个特定的请求。
 * `rxrProtocolHost` 是对这些特定请求的 scheme 的商定。如不设置，缺省为 douban。
 */
+ (void)setRXRProtocolScheme:(NSString *)scheme;

/**
 * 读取 rxrProtocolScheme。
 *
 * @discussion Rexxar-Container 实现了一些供 Web 调用的功能。Web 调用这些功能的方式是发出一个特定的请求。
 * `rxrProtocolHost` 是对这些特定请求的 scheme 的商定。如不设置，缺省为 douban。
 */
+ (NSString *)rxrProtocolScheme;

/**
 * 设置 rxrProtocolHost。
 *
 * @discussion Rexxar-Container 实现了一些供 Web 调用的功能。Web 调用这些功能的方式是发出一个特定的请求。
 * `rxrProtocolHost` 是对这些特定请求的 host 的商定。如不设置，缺省为 rexxar-container。
 */
+ (void)setRXRProtocolHost:(NSString *)host;

/**
 * 读取 rxrProtocolHost。
 *
 * @discussion Rexxar-Container 实现了一些供 Web 调用的功能。Web 调用这些功能的方式是发出一个特定的请求。
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
+ (void)setUserAgent:(NSString *)userAgent;

/**
 * 读取 Rexxar 接收的外部 User-Agent。
 */
+ (NSString *)userAgent;

/**
 * 设置请求参数列表，Rexxar 会将这些参数加到其发出的所有请求的 url query 中。
 */
+ (void)setExtraRequestParams:(NSArray<NSURLQueryItem *> *)params;

/**
 * 读取请求参数列表。
 */
+ (NSArray<NSURLQueryItem *> *)extraRequestParams;

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

/**
 * 设置 RXRRouteManager 是否忽略 routes 版本。缺省 NO。
 * 缺省设置下，RXRRouteManager 会根据拉取的 routes 版本跟本地已拉取的 routes 版本比较，只有版本更大的情况下才会更新 routes 文件。
 * 如果设置为 YES，RXRRouteManager 检查 routes 文件更新时，将不比较 version 版本大小，立刻更新到新获取到的 routes。
 * 建议在本地开发中设置为 YES，线上版本为缺省设置 NO。
 */
+ (void)setNeedsIgnoreRoutesVersion:(BOOL)needsIgnoreRoutesVersion;

+ (BOOL)needsIgnoreRoutesVersion;

/**
 设置 `RXRDataValidator`。设置后，将会在下载 HTML file 时验证文件合法性（可用来做完整性检验）。
 */
+ (void)setHTMLFileDataValidator:(id<RXRDataValidator>)dataValidator;

/**
 设置 Rexxar 所有请求的 URLSessionConfiguration
 */
+ (void)setRequestsURLSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration;

/**
 获取 Rexxar 所有请求的 URLSessionConfiguration
 */
+ (NSURLSessionConfiguration *)requestsURLSessionConfiguration;

@end

NS_ASSUME_NONNULL_END
