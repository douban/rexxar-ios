//
//  RXRRequestInterceptor.m
//  Rexxar
//
//  Created by bigyelow on 09/03/2017.
//  Copyright © 2017 Douban.Inc. All rights reserved.
//

#import "RXRRequestInterceptor.h"

static NSArray<id<RXRDecorator>> *_decorators;

@implementation RXRRequestInterceptor

#pragma mark - Properties

- (NSArray<id<RXRDecorator>> *)decorators
{
  return _decorators;
}

+ (void)setDecorators:(NSArray<id<RXRDecorator>> *)decorators
{
  _decorators = [decorators copy];
}

#pragma mark - Superclass methods

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

  for (id<RXRDecorator> decorator in _decorators) {
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

  for (id<RXRDecorator> decorator in _decorators) {
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

@end
