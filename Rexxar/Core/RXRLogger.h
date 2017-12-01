//
//  RXRLogger.h
//  Rexxar
//
//  Created by bigyelow on 07/11/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

#ifdef DEBUG
#define RXRLog(...) NSLog(@"[Rexxar] " __VA_ARGS__)
#else /* DEBUG */
#define RXRLog(...)
#endif /* DEBUG */

#define RXRDebugLog(...)  RXRLog(@"[DEBUG] " __VA_ARGS__)
#define RXRWarnLog(...)   RXRLog(@"[WARN] " __VA_ARGS__)
#define RXRErrorLog(...)  RXRLog(@"[ERROR] " __VA_ARGS__)

@import Foundation;
@class RXRLogObject;

typedef enum : NSUInteger {
  RXRLogTypeNoRoutesMapURLError,  // 没有设置 RoutesMap 地址
  RXRLogTypeDownloadingRoutesError, // 下载 Routes 失败
  RXRLogTypeDownloadingHTMLFileError, // 下载 HTML file 失败
  RXRLogTypeValidatingHTMLFileError,  // 验证下载的 HTML file 失败（需要提供 `RXRDataValidator`）
  RXRLogTypeFailedToCreateCacheDirectoryError,  // 创建 cache 目录失败
  RXRLogTypeWebViewLoadingError,  // WebView 加载失败
  RXRLogTypeNoRemoteHTMLForURI, // 在内存中的 route 列表里找不到 uri 对应的项（没有对应的 html 文件名）
  RXRLogTypeNoLocalHTMLForURI,  // 在内存中的 route 列表里找不到 uri 对应的本地 html 文件
  RXRLogTypeUnknown,
} RXRLogType;

/**
 可在 `RXRConfig` 中设置，`Rexar` 不提供默认实现。如果设置了 `RXRLogger`，将会提供 `RXRLogType` 中所包含类型的记录。
 */
@protocol RXRLogger <NSObject>

/**
 `RXRLogger` 目前只提供这一个方法，需要调用者实现。调用者获取到 `logObject` 后自己处理具体的 log 逻辑。

 @param logObject 由 `RXRLogObject` 封装的 log 记录。
 */
- (void)rexxarDidLogWithLogObject:(nonnull RXRLogObject *)logObject;

@end

FOUNDATION_EXPORT const NSString * _Nonnull logOtherInfoStatusCodeKey;
FOUNDATION_EXPORT const NSString * _Nonnull logOtherInfoRoutesDepolyTimeKey;

NS_ASSUME_NONNULL_BEGIN
@interface RXRLogObject : NSObject

@property (nonatomic, readonly) RXRLogType type;
@property (nonatomic, readonly) NSString *logDescription;
@property (nonatomic, readonly, nullable) NSError *error;
@property (nonatomic, readonly, nullable) NSURL *requestURL;
@property (nonatomic, readonly, nullable) NSString *localFilePath;
@property (nonatomic, readonly, nullable) NSDictionary *otherInfomation;  // 目前 Rexxar 只提供 `logOtherInfoStatusCodeKey`

- (instancetype)initWithLogType:(RXRLogType)type
                          error:(nullable NSError *)error
                     requestURL:(nullable NSURL *)requestURL
                  localFilePath:(nullable NSString *)localFilePath
               otherInformation:(nullable NSDictionary *)otherInformation;

- (instancetype)initWithLogDescription:(nullable NSString *)description
                                 error:(nullable NSError *)error
                            requestURL:(nullable NSURL *)requestURL
                         localFilePath:(nullable NSString *)localFilePath
                      otherInformation:(nullable NSDictionary *)otherInformation NS_DESIGNATED_INITIALIZER;

NS_ASSUME_NONNULL_END

@end
