//
//  NSURLResponse+Rexxar.m
//  Rexxar
//
//  Created by XueMing on 02/03/2017.
//  Copyright © 2017 Douban.Inc. All rights reserved.
//

#import "NSURLResponse+Rexxar.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSURLResponse (Rexxar)

+ (NSDictionary *)_rxr_noAccessControlHeaderFields
{
  static NSDictionary *headerFields = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    headerFields = @{@"Access-Control-Allow-Headers": @"Origin, X-Requested-With, Content-Type",
                     @"Access-Control-Allow-Origin": @"*"};
  });
  return headerFields;
}

+ (instancetype)rxr_noAccessControlHeaderInstanceForRequest:(NSURLRequest *)request
{
  NSDictionary *headerFields = [[self class] _rxr_noAccessControlHeaderFields];
  return [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                     statusCode:200
                                    HTTPVersion:@"HTTP/1.1"
                                   headerFields:headerFields];
}

+ (instancetype)rxr_noAccessControlHeaderInstanceWithResponse:(NSURLResponse *)response
{
  if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
    NSHTTPURLResponse *URLResponse = (NSHTTPURLResponse *)response;
    NSDictionary *headerFields = [[self class] _rxr_noAccessControlHeaderFields];
    if ([URLResponse.allHeaderFields count] > 0) {
      NSMutableDictionary *mutableHeaderFields = [URLResponse.allHeaderFields mutableCopy];
      [mutableHeaderFields addEntriesFromDictionary:headerFields];
      headerFields = mutableHeaderFields;
    }

    return [[NSHTTPURLResponse alloc] initWithURL:URLResponse.URL
                                       statusCode:URLResponse.statusCode
                                      HTTPVersion:@"HTTP/1.1"
                                     headerFields:headerFields];
  }

  return response;
}

@end

NS_ASSUME_NONNULL_END
