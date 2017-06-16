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

@interface RXRRequestDecorator ()

@property (nonatomic, strong) RXRHTTPRequestSerializer *requestSerializer;

@end

@implementation RXRRequestDecorator

- (instancetype)init
{
  return [self initWithHeaders:@{} parameters:@{}];
}

- (instancetype)initWithHeaders:(NSDictionary *)headers
                     parameters:(NSDictionary *)parameters
{
  self = [super init];
  if (self) {
    _headers = [headers copy];
    _parameters = [parameters copy];
    _requestSerializer = [[RXRHTTPRequestSerializer alloc] init];
  }
  return self;
}

- (BOOL)shouldInterceptRequest:(NSURLRequest *)request
{
  // 只处理 Http 和 https 请求
  if (![request.URL rxr_isHttpOrHttps]) {
    return NO;
  }

  // 不处理静态资源文件
  if ([[self class] _rxr_isStaticResourceRequest:request]) {
    return NO;
  }

  return YES;
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

  // Note: mutableRequest.URL.query has been added to the paramters, _requestSerializer will generate a new NSURLRequest
  // object from the parameters every time when it decorates a request. If we don't remove query from URL, request may
  // contain duplicated query string if the original request is decorated more than 2 times.
  NSURLComponents *comp = [[NSURLComponents alloc] initWithURL:mutableRequest.URL resolvingAgainstBaseURL:NO];
  comp.query = nil;
  mutableRequest.URL = comp.URL;

  return [_requestSerializer requestBySerializingRequest:mutableRequest
                                          withParameters:parameters
                                                   error:nil];
}

#pragma mark - Private methods

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


+ (BOOL)_rxr_isStaticResourceRequest:(NSURLRequest *)request
{
  NSString *extension = request.URL.pathExtension;
  if ([extension isEqualToString:@"js"] ||
      [extension isEqualToString:@"css"] ||
      [extension isEqualToString:@"html"]) {
    return YES;
  }
  return NO;
}

@end
