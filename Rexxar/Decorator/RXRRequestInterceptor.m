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
  __block BOOL result;
  dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_barrier_sync(globalQueue, ^{

    if (sRegisterInterceptorCounter <= 0) {
      result = [NSURLProtocol registerClass:[self class]];
      if (result) {
        sRegisterInterceptorCounter = 1;
      }
    } else {
      sRegisterInterceptorCounter++;
      result = YES;
    }

  });

  return result;
}

+ (void)unregisterInterceptor
{
  dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_barrier_async(globalQueue, ^{

    sRegisterInterceptorCounter--;
    if (sRegisterInterceptorCounter < 0) {
      sRegisterInterceptorCounter = 0;
    }

    if (sRegisterInterceptorCounter == 0) {
      [NSURLProtocol unregisterClass:[self class]];
    }
  });
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

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
  NSMutableURLRequest *newRequest = nil;
  if ([request isKindOfClass:[NSMutableURLRequest class]]) {
    newRequest = (NSMutableURLRequest *)request;
  } else {
    newRequest = [request mutableCopy];
  }

  for (id<RXRDecorator> decorator in sDecorators) {
    if ([decorator shouldInterceptRequest:request]) {
      if ([decorator respondsToSelector:@selector(prepareWithRequest:)]) {
        [decorator prepareWithRequest:request];
      }
      newRequest = [[decorator decoratedRequestFromOriginalRequest:newRequest] mutableCopy];
    }
  }

  [self markRequestAsIgnored:newRequest];

  return newRequest;
}

- (void)startLoading
{
  NSParameterAssert([self dataTask] == nil);

  NSURLSessionTask *dataTask = [[self URLSession] dataTaskWithRequest:self.request];
  [dataTask resume];
  [self setDataTask:dataTask];
}

@end
