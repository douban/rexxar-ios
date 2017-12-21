//
//  RXRConfig+Rexxar.h
//  Rexxar
//
//  Created by bigyelow on 21/12/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

#import "RXRConfig.h"
@class RXRLogObject;

NS_ASSUME_NONNULL_BEGIN
@interface RXRConfig (Rexxar)

+ (BOOL)rxr_canLog;
+ (void)rxr_logWithLogObject:(nullable RXRLogObject *)object;

+ (BOOL)rxr_canHandleError;
+ (void)rxr_handleError:(nullable NSError *)error fromReporter:(nullable id)reporter;

@end
NS_ASSUME_NONNULL_END
