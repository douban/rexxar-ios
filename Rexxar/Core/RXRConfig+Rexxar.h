//
//  RXRConfig+Rexxar.h
//  Rexxar
//
//  Created by bigyelow on 21/12/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

#import <Rexxar/Rexxar.h>
@class RXRLogObject;

NS_ASSUME_NONNULL_BEGIN
@interface RXRConfig (Rexxar)

+ (BOOL)rxr_canLog;
+ (void)rxr_logWithLogObject:(nullable RXRLogObject *)object;

+ (BOOL)rxr_canHandleError;
+ (void)rxr_reporter:(nullable id)reporter handleError:(nullable NSError *)error;

@end
NS_ASSUME_NONNULL_END
