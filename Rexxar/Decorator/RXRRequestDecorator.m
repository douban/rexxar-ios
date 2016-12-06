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
  [self _rxr_addQuery:mutableRequest.URL.query toParameters:parameters];

  // Get parameters from POST request body
  // Note: `requestBySerializingRequest:withParameters:error:` method will add query to HTTP body for POST request
  if ([mutableRequest.HTTPMethod.uppercaseString isEqualToString:@"POST"]
      && mutableRequest.HTTPBody
      && [[[mutableRequest valueForHTTPHeaderField:@"Content-Type"] lowercaseString] isEqualToString:@"application/x-www-form-urlencoded"]) {
    NSString *bodyQueries = [[NSString alloc] initWithData:mutableRequest.HTTPBody encoding:kCFStringEncodingUTF8];
    [self _rxr_addQuery:bodyQueries toParameters:parameters];
  }

  // Remove query from url because RXRHTTPRequestSerializer will add all the parameters through
  // `requestBySerializingRequest:withParameters:error:` method.
  NSURLComponents *comp = [[NSURLComponents alloc] initWithURL:mutableRequest.URL resolvingAgainstBaseURL:NO];
  comp.query = nil;
  mutableRequest.URL = comp.URL;

  return [[RXRHTTPRequestSerializer serializer] requestBySerializingRequest:[mutableRequest copy]
                                                             withParameters:parameters
                                                                      error:nil];
}

- (void)_rxr_addQuery:(NSString *)query toParameters:(NSMutableDictionary *)parameters
{
  if (!parameters) {
    return;
  }

  for (NSString *pair in [query componentsSeparatedByString:@"&"]) {
    NSArray *keyValuePair = [pair componentsSeparatedByString:@"="];
    if (keyValuePair.count != 2) {
      continue;
    }

    NSString *key = [keyValuePair[0] stringByRemovingPercentEncoding];
    if (parameters[key] == nil) {
      parameters[key] = [keyValuePair[1] stringByRemovingPercentEncoding];
    }
  }
}

@end
