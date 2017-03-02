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

+ (NSDictionary<NSString *, NSString *> *)_rxr_noAccessControlHeaderFields
{
  static NSDictionary<NSString *, NSString *> *headerFields = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    headerFields = @{@"Access-Control-Allow-Headers": @"Origin, X-Requested-With, Content-Type",
                     @"Access-Control-Allow-Origin": @"*"};
  });
  return headerFields;
}

+ (instancetype)rxr_defaultResponseForRequest:(NSURLRequest *)request
{
  NSDictionary *headerFields = [[self class] _rxr_noAccessControlHeaderFields];
  return [[[self class] alloc] initWithURL:request.URL
                                statusCode:200
                               HTTPVersion:@"HTTP/1.1"
                              headerFields:headerFields];
}

- (instancetype)rxr_noAccessControlResponse
{
  if (![self isKindOfClass:[NSHTTPURLResponse class]]) {
    return self;
  }

  NSHTTPURLResponse *URLResponse = (NSHTTPURLResponse *)self;
  NSDictionary *headerFields = [[self class] _rxr_noAccessControlHeaderFields];

  if ([URLResponse.allHeaderFields count] > 0) {
    NSMutableDictionary *mutableHeaderFields = [URLResponse.allHeaderFields mutableCopy];
    [mutableHeaderFields addEntriesFromDictionary:headerFields];
    headerFields = mutableHeaderFields;
  }

  return [[[self class] alloc] initWithURL:URLResponse.URL
                                statusCode:URLResponse.statusCode
                               HTTPVersion:@"HTTP/1.1"
                              headerFields:headerFields];
}

@end

NS_ASSUME_NONNULL_END
