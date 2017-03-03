//
//  NSHTTPURLResponse+Rexxar.m
//  Rexxar
//
//  Created by XueMing on 03/03/2017.
//  Copyright © 2017 Douban.Inc. All rights reserved.
//

#import "NSHTTPURLResponse+Rexxar.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSHTTPURLResponse (Rexxar)

+ (nullable instancetype)rxr_responseWithURL:(NSURL *)url
                                  statusCode:(NSInteger)statusCode
                                headerFields:(nullable NSDictionary<NSString *, NSString *> *)headerFields
                             noAccessControl:(BOOL)noAccessControl
{
  if (!noAccessControl) {
    return [[NSHTTPURLResponse alloc] initWithURL:url statusCode:statusCode HTTPVersion:@"HTTP/1.1" headerFields:headerFields];
  }

  NSMutableDictionary<NSString *, NSString *> *mutableHeaderFields = [NSMutableDictionary<NSString *, NSString *> dictionary];
  [mutableHeaderFields setValue:@"*" forKey:@"Access-Control-Allow-Origin"];
  [mutableHeaderFields setValue:@"Origin, X-Requested-With, Content-Type" forKey:@"Access-Control-Allow-Headers"];

  if (headerFields != nil && [headerFields count] > 0) {
    [mutableHeaderFields addEntriesFromDictionary:headerFields];
  }

  return [[NSHTTPURLResponse alloc] initWithURL:url statusCode:statusCode HTTPVersion:@"HTTP/1.1" headerFields:mutableHeaderFields];
}

@end

NS_ASSUME_NONNULL_END

