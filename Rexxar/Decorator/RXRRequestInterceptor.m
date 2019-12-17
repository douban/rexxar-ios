//
//  RXRRequestInterceptor.m
//  Rexxar
//
//  Created by bigyelow on 09/03/2017.
//  Copyright © 2017 Douban.Inc. All rights reserved.
//

@import UIKit;

#import "RXRRequestInterceptor.h"
#import "RXRURLSessionDemux.h"
#import "RXRConfig.h"

static NSArray<id<RXRDecorator>> *_decorators;
static NSArray<id<RXRProxy>> *_proxies;

@implementation RXRRequestInterceptor

#pragma mark - Properties

+ (NSArray<id<RXRDecorator>> *)decorators
{
  return _decorators;
}

+ (void)setDecorators:(NSArray<id<RXRDecorator>> *)decorators
{
  _decorators = [decorators copy];
}

+ (NSArray<id<RXRProxy>> *)proxies
{
  return _proxies;
}

+ (void)setProxies:(NSArray<id<RXRProxy>> *)proxies
{
  _proxies = [proxies copy];
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

  for (id<RXRProxy> proxy in _proxies) {
    if ([proxy shouldInterceptRequest:request]) {
      return YES;
    }
  }

  for (id<RXRDecorator> decorator in _decorators) {
    if ([decorator shouldInterceptRequest:request]){
      return YES;
    }
  }

  return NO;
}

- (void)startLoading
{
  [self beforeStartLoadingRequest];

  for (id<RXRProxy> proxy in _proxies) {
    if ([proxy shouldInterceptRequest:self.request]) {
      NSURLResponse *response = [proxy responseWithRequest:self.request];
      if (response != nil) {
        NSData *data = [proxy responseDataWithRequest:self.request];
        if (data != nil) {
          [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
          [self.client URLProtocol:self didLoadData:data];
          [self.client URLProtocolDidFinishLoading:self];
          if ([proxy respondsToSelector:@selector(proxyDidFinishWithRequest:)]) {
            [proxy proxyDidFinishWithRequest:self.request];
          }
          return;
        }
      }
    }
  }

  NSMutableURLRequest *newRequest = [self _rxr_decorateRequest:self.request];
  NSMutableArray *modes = [NSMutableArray array];
  [modes addObject:NSDefaultRunLoopMode];

  NSString *currentMode = [[NSRunLoop currentRunLoop] currentMode];
  if (currentMode != nil && ![currentMode isEqualToString:NSDefaultRunLoopMode]) {
    [modes addObject:currentMode];
  }
  [self setModes:modes];

  [NSURLProtocol setProperty:@([NSDate timeIntervalSinceReferenceDate]) forKey:@"StartTime" inRequest:newRequest];
  NSURLSessionTask *dataTask = [[[self class] sharedDemux] dataTaskWithRequest:newRequest delegate:self modes:self.modes];
  [dataTask resume];
  [self setDataTask:dataTask];
}

- (NSMutableURLRequest *)_rxr_decorateRequest:(NSURLRequest *)request
{
  NSMutableURLRequest *newRequest = nil;

  if ([request isKindOfClass:[NSMutableURLRequest class]]) {
    newRequest = (NSMutableURLRequest *)request;
  } else {
    newRequest = [request mutableCopy];
  }

  for (id<RXRDecorator> decorator in _decorators) {
    if ([decorator shouldInterceptRequest:newRequest]) {
      if ([decorator respondsToSelector:@selector(prepareWithRequest:)]) {
        [decorator prepareWithRequest:newRequest];
      }
      newRequest = [[decorator decoratedRequestFromOriginalRequest:newRequest] mutableCopy];
    }
  }

  // 由于在 iOS9 及以下版本对 WKWebView 缓存支持不好，所有的请求不使用缓存
  if ([[[UIDevice currentDevice] systemVersion] compare:@"10.0" options:NSNumericSearch] == NSOrderedAscending) {
    [newRequest setValue:nil forHTTPHeaderField:@"If-None-Match"];
    [newRequest setValue:nil forHTTPHeaderField:@"If-Modified-Since"];
  }

  [[self class] markRequestAsIgnored:newRequest];

  return newRequest;
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
  NSMutableURLRequest *newRequest = [task.currentRequest mutableCopy];
  [newRequest setURL:request.URL];

  newRequest = [self _rxr_decorateRequest:newRequest];
  completionHandler(newRequest);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
  [super URLSession:session task:task didCompleteWithError:error];
  
  NSNumber *startNum = [NSURLProtocol propertyForKey:@"StartTime" inRequest:task.originalRequest];
  NSTimeInterval startTime = [startNum doubleValue];
  if (RXRConfig.didCompleteRequestBlock) {
    RXRConfig.didCompleteRequestBlock(task.originalRequest.URL, task.response, error, [NSDate timeIntervalSinceReferenceDate] - startTime);
  }
}

@end
