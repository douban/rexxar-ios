//
//  RXRRequestDecorator.m
//  Rexxar
//
//  Created by GUO Lin on 7/1/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

#import "RXRRequestDecorator.h"

#import "NSURL+Rexxar.h"

@implementation RXRRequestDecorator

- (instancetype)initWithHeaders:(NSDictionary *)headers
                     parameters:(NSDictionary *)parameters
{
  self = [super init];
  if (self) {
    _headers = headers;
    _parameters = parameters;
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

- (void)decorateRequest:(NSMutableURLRequest *)request
{
  // Request headers
  [self.headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    if ([key isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]]){
      [request setValue:obj forHTTPHeaderField:key];
    }
  }];

  // Request url parameters
  NSMutableDictionary *parametersEncoded = [NSMutableDictionary dictionaryWithDictionary:self.parameters];
  for (NSString *pair in [request.URL.query componentsSeparatedByString:@"&"]) {

    NSArray *keyValuePair = [pair componentsSeparatedByString:@"="];
    if (keyValuePair.count != 2) {
      continue;
    }

    NSString *key = [keyValuePair[0] stringByRemovingPercentEncoding];
    if (parametersEncoded[key] == nil) {
      parametersEncoded[key] = [keyValuePair[1] stringByRemovingPercentEncoding];
    }
  }

  NSString *query = [NSURL rxr_queryFromDictionary:parametersEncoded];
  if (query) {
    NSURLComponents *urlComps = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:YES];
    urlComps.query = query;
    request.URL = urlComps.URL;
  }
}

@end
