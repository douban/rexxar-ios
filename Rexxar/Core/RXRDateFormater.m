//
//  RXRDateFormater.m
//  Rexxar
//
//  Created by Ming Xue on 5/13/20.
//  Copyright © 2020 Douban Inc. All rights reserved.
//

#import "RXRDateFormater.h"

NSString *const RXRDeployTimeFormat = @"EEE, d MMM yyyy HH:mm:ss";

@implementation RXRDateFormater

+ (NSString *)stringFromDate:(NSDate *)date format:(NSString *)fmt
{
  NSDateFormatter *formatter = [[self class] dateFormatterWithFormat:fmt];
  return [formatter stringFromDate:date];
}

+ (NSDate *)dateFromString:(NSString *)date format:(NSString *)fmt
{
  NSDateFormatter *formatter = [[self class] dateFormatterWithFormat:fmt];
  return [formatter dateFromString:date];
}

+ (NSDateFormatter *)dateFormatterWithFormat:(NSString *)fmt
{
  static NSCache *cache = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cache = [[NSCache alloc] init];
  });

  NSDateFormatter *instance = [cache objectForKey:fmt];
  if (instance == nil) {
    @synchronized(cache) {
      instance = [cache objectForKey:fmt];
      if (instance == nil) {
        instance = [[NSDateFormatter alloc] init];
        instance.dateFormat = fmt;
        instance.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:8 * 60 * 60];
        [cache setObject:instance forKey:fmt];
      }
    }
  }
  return instance;
}

@end
