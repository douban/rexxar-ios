//
//  RXRRequestIntercepter.m
//  Rexxar
//
//  Created by GUO Lin on 5/17/16.
//  Copyright © 2016 Douban Inc. All rights reserved.
//

#import "RXRRequestIntercepter.h"

#import "RXRDecorator.h"

static NSArray<id<RXRDecorator>> *sDecorators;

@implementation RXRRequestIntercepter

+ (void)setDecorators:(NSArray<id<RXRDecorator>> *)decorators
{
  sDecorators = decorators;
}

+ (NSArray<id<RXRDecorator>> *)decorators
{
  return sDecorators;
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
  NSParameterAssert(self.connection == nil);
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
      [decorator decorateRequest:request];
    }
  }

  [[self class] markRequestAsIgnored:request];
  self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

@end
