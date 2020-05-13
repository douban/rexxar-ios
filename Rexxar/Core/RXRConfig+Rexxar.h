//
//  RXRConfig+Rexxar.h
//  Rexxar
//
//  Created by bigyelow on 21/12/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

#import "RXRConfig.h"
#import "RXRLogger.h"

NS_ASSUME_NONNULL_BEGIN

@interface RXRConfig (Rexxar)

+ (BOOL)rxr_canLog;
+ (void)rxr_logWithLogObject:(nullable RXRLogObject *)object;
+ (void)rxr_logWithType:(RXRLogType)type
                  error:(nullable NSError *)error
             requestURL:(nullable NSURL *)url
          localFilePath:(nullable NSString *)localFilePath
               userInfo:(nullable NSDictionary *)userInfo;

+ (BOOL)rxr_canHandleError;
+ (void)rxr_handleError:(nullable NSError *)error fromReporter:(nullable id)reporter;

@end

NS_ASSUME_NONNULL_END
