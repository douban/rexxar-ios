//
//  RXRRequestDecorator.m
//  Rexxar
//
//  Created by GUO Lin on 7/1/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

#import "RXRURLRequestSerialization.h"
#import "RXRRequestDecorator.h"

#import "NSURL+Rexxar.h"

@implementation RXRRequestDecorator

- (instancetype)initWithHeaders:(NSDictionary *)headers
                     parameters:(NSDictionary *)parameters
{
  self = [super init];
  if (self) {
    _headers = [headers copy];
    _parameters = [parameters copy];
  }
  return self;
}

- (BOOL)shouldInterceptRequest:(NSURLRequest *)request
{
  if ([request.URL rxr_isHttpOrHttps]) {
    return YES;
  }

  return NO;
}

- (NSURLRequest *)decoratedRequestFromOriginalRequest:(NSURLRequest *)originalRequest
{
  NSMutableURLRequest *mutableRequest = [originalRequest mutableCopy];

  // Request headers
  [self.headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    if ([key isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]]){
      [mutableRequest setValue:obj forHTTPHeaderField:key];
    }
  }];

  // Request url parameters
  NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:self.parameters];
  for (NSString *pair in [mutableRequest.URL.query componentsSeparatedByString:@"&"]) {

    NSArray *keyValuePair = [pair componentsSeparatedByString:@"="];
    if (keyValuePair.count != 2) {
      continue;
    }

    NSString *key = [keyValuePair[0] stringByRemovingPercentEncoding];
    if (parameters[key] == nil) {
      parameters[key] = [keyValuePair[1] stringByRemovingPercentEncoding];
    }
  }

  return [[RXRHTTPRequestSerializer serializer] requestBySerializingRequest:[mutableRequest copy]
                                                             withParameters:parameters
                                                                      error:nil];
}

@end
