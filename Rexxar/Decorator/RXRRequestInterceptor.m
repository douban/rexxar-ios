//
//  RXRRequestInterceptor.m
//  Rexxar
//
//  Created by GUO Lin on 5/17/16.
//  Copyright © 2016 Douban Inc. All rights reserved.
//

#import "RXRRequestInterceptor.h"

#import "RXRDecorator.h"

static NSArray<id<RXRDecorator>> *sDecorators;
static NSInteger sRegisterInterceptorCounter;

@implementation RXRRequestInterceptor

+ (void)setDecorators:(NSArray<id<RXRDecorator>> *)decorators
{
  sDecorators = decorators;
}

+ (NSArray<id<RXRDecorator>> *)decorators
{
  return sDecorators;
}

+ (BOOL)registerInterceptor
{
  @synchronized (self) {
    sRegisterInterceptorCounter += 1;
  }
  return [NSURLProtocol registerClass:[self class]];
}

+ (void)unregisterInterceptor
{
  @synchronized (self) {
    sRegisterInterceptorCounter -= 1;
    if (sRegisterInterceptorCounter < 0) {
      sRegisterInterceptorCounter = 0;
    }
  }

  if (sRegisterInterceptorCounter == 0) {
    return [NSURLProtocol unregisterClass:[self class]];
  }
}

#pragma mark - Implement NSURLProtocol methods

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
  // 请求被忽略（被标记为忽略或者已经请求过），不处理
  if ([self isRequestIgnored:request]) {
    return NO;
  }
  // 请求不是来自浏览器，不处理
  if (![request.allHTTPHeaderFields[@"User-Agent"] hasPrefix:@"Mozilla"]) {
    return NO;
  }

  for (id<RXRDecorator> decorator in sDecorators) {
    if ([decorator shouldInterceptRequest:request]){
      return YES;
    }
  }

  return NO;
}

- (void)startLoading
{
  NSParameterAssert([self dataTask] == nil);
  NSParameterAssert([[self class] canInitWithRequest:self.request]);

  __block NSMutableURLRequest *request = nil;
  if ([self.request isKindOfClass:[NSMutableURLRequest class]]) {
    request = (NSMutableURLRequest *)self.request;
  } else {
    request = [self.request mutableCopy];
  }

  for (id<RXRDecorator> decorator in sDecorators) {
    if ([decorator shouldInterceptRequest:request]) {
      if ([decorator respondsToSelector:@selector(prepareWithRequest:)]) {
        [decorator prepareWithRequest:request];
      }
      request = [[decorator decoratedRequestFromOriginalRequest:request] mutableCopy];
    }
  }

  [[self class] markRequestAsIgnored:request];

  NSURLSessionTask *dataTask = [[self URLSession] dataTaskWithRequest:request];
  [dataTask resume];
  [self setDataTask:dataTask];
}

@end
