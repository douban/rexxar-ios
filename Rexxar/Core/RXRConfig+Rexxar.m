//
//  RXRConfig+Rexxar.m
//  Rexxar
//
//  Created by bigyelow on 21/12/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

#import "RXRConfig+Rexxar.h"
#import "RXRLogger.h"

@implementation RXRConfig (Rexxar)

+ (void)rxr_logWithLogObject:(RXRLogObject *)object
{
  if (self.logger && [self.logger respondsToSelector:@selector(rexxarDidLogWithLogObject:)] && object) {
    [self.logger rexxarDidLogWithLogObject:object];
  }
}

+ (BOOL)rxr_canLog
{
  return self.logger && [self.logger respondsToSelector:@selector(rexxarDidLogWithLogObject:)];
}

+ (void)rxr_handleError:(NSError *)error
{

}

@end
