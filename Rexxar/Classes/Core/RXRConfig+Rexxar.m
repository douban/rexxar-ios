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
