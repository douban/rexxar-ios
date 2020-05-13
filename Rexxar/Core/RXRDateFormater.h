//
//  RXRDateFormater.h
//  Rexxar
//
//  Created by Ming Xue on 5/13/20.
//  Copyright © 2020 Douban Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const RXRDeployTimeFormat;

@interface RXRDateFormater : NSObject

+ (nullable NSString *)stringFromDate:(NSDate *)date format:(NSString *)fmt;
+ (nullable NSDate *)dateFromString:(NSString *)date format:(NSString *)fmt;

@end

NS_ASSUME_NONNULL_END
