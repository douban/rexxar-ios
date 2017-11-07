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
  RXRLogTypeNoRoutesMapURLError,
  RXRLogTypeDownloadingRoutesError,
  RXRLogTypeDownloadingHTMLFileError,
  RXRLogTypeValidatingHTMLFileError,
  RXRLogTypeFailedToCreateCacheDirectoryError,
  RXRLogTypeWebViewLoadingError,
  RXRLogTypeUnknown,
} RXRLogType;

@protocol RXRLogger <NSObject>

- (void)rexxarDidLogWithLogObject:(nonnull RXRLogObject *)logObject;

@end

FOUNDATION_EXPORT NSString * _Nonnull logOtherInfoStatusCodeKey;

NS_ASSUME_NONNULL_BEGIN
@interface RXRLogObject : NSObject

@property (nonatomic, readonly) RXRLogType type;
@property (nonatomic, readonly) NSString *logDescription;
@property (nonatomic, readonly, nullable) NSError *error;
@property (nonatomic, readonly, nullable) NSURL *requestURL;
@property (nonatomic, readonly, nullable) NSString *localFilePath;
@property (nonatomic, readonly, nullable) NSDictionary *otherInfomation;

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
