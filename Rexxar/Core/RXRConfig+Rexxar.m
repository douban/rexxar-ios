//
//  RXRConfig+Rexxar.m
//  Rexxar
//
//  Created by bigyelow on 21/12/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

#import "RXRConfig+Rexxar.h"
#import "RXRLogger.h"
#import "RXRErrorHandler.h"
#import "RXRRouteManager.h"

@implementation RXRConfig (Rexxar)

+ (BOOL)rxr_canLog
{
  return self.logger && [self.logger respondsToSelector:@selector(rexxarDidLogWithLogObject:)];
}

+ (void)rxr_logWithLogObject:(RXRLogObject *)object
{
  if ([self rxr_canLog] && object) {
    [self.logger rexxarDidLogWithLogObject:object];
  }
}

+ (void)rxr_logWithType:(RXRLogType)type
                  error:(NSError *)error
             requestURL:(NSURL *)url
          localFilePath:(NSString *)localFilePath
               userInfo:(nullable NSDictionary *)userInfo
{
  if (![self rxr_canLog]) {
    return;
  }

  NSMutableDictionary *info = [NSMutableDictionary dictionary];
  [info setValue:[RXRRouteManager sharedInstance].routesDeployTime forKey:logOtherInfoRoutesDepolyTimeKey];
  if (userInfo != nil) {
    [info addEntriesFromDictionary:userInfo];
  }
  RXRLogObject *obj = [[RXRLogObject alloc] initWithLogType:type error:error requestURL:url localFilePath:localFilePath otherInformation:info];
  [RXRConfig rxr_logWithLogObject:obj];
}

+ (BOOL)rxr_canHandleError
{
  return self.errorHandler && [self.errorHandler respondsToSelector:@selector(handleError:fromReporter:)];
}

+ (void)rxr_handleError:(NSError *)error fromReporter:(id)reporter
{
  if ([self rxr_canHandleError] && error) {
    [self.errorHandler handleError:error fromReporter:reporter];
  }
}

@end
