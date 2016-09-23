//
//  RXRContainerIntercepter.m
//  Rexxar
//
//  Created by GUO Lin on 5/17/16.
//  Copyright © 2016 Douban Inc. All rights reserved.
//

#import "RXRContainerIntercepter.h"
#import "RXRContainerAPI.h"

static NSArray<id<RXRContainerAPI>> *sContainerAPIs;

@implementation RXRContainerIntercepter

+ (void)setContainerAPIs:(NSArray<id<RXRContainerAPI>> *)mockers
{
  sContainerAPIs = mockers;
}

+ (NSArray<id<RXRContainerAPI>> *)containerAPIs
{
  return sContainerAPIs;
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
  // 请求不是来自浏览器，不处理
  if (![request.allHTTPHeaderFields[@"User-Agent"] hasPrefix:@"Mozilla"]) {
    return NO;
  }

  for (id<RXRContainerAPI> mocker in sContainerAPIs) {
    if ([mocker shouldInterceptRequest:request]) {
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
