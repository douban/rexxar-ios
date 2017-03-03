//
//  RXRContainerInterceptor.m
//  Rexxar
//
//  Created by GUO Lin on 5/17/16.
//  Copyright © 2016 Douban Inc. All rights reserved.
//

#import "RXRContainerInterceptor.h"
#import "NSHTTPURLResponse+Rexxar.h"
#import "RXRContainerAPI.h"

static NSArray<id<RXRContainerAPI>> *sContainerAPIs;
static NSInteger sRegisterInterceptorCounter;

@implementation RXRContainerInterceptor

+ (void)setContainerAPIs:(NSArray<id<RXRContainerAPI>> *)mockers
{
  sContainerAPIs = mockers;
}

+ (NSArray<id<RXRContainerAPI>> *)containerAPIs
{
  return sContainerAPIs;
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
  // 请求不是来自浏览器，不处理
  if (![request.allHTTPHeaderFields[@"User-Agent"] hasPrefix:@"Mozilla"]) {
    return NO;
  }

  for (id<RXRContainerAPI> containerAPI in sContainerAPIs) {
    if ([containerAPI shouldInterceptRequest:request]) {
      return YES;
    }
  }

  return NO;
}

- (void)startLoading
{
  for (id<RXRContainerAPI> containerAPI in sContainerAPIs) {
    if ([containerAPI shouldInterceptRequest:self.request]) {

      if ([containerAPI respondsToSelector:@selector(prepareWithRequest:)]) {
        [containerAPI prepareWithRequest:self.request];
      }

      if ([containerAPI respondsToSelector:@selector(performWithRequest:)]) {
        [containerAPI performWithRequest:self.request];
      }

      NSData *data = [containerAPI responseData];
      NSURLResponse *response = [containerAPI responseWithRequest:self.request];
      [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
      [self.client URLProtocol:self didLoadData:data];
      [self.client URLProtocolDidFinishLoading:self];
      break;
    }
  }
}

@end
