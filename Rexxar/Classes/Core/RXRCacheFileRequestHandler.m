//
//  RXRCacheFileRequestHandler.m
//  MTURLProtocol
//
//  Created by bigyelow on 2018/8/23.
//

#import "RXRCacheFileRequestHandler.h"
#import "NSURLRequest+Rexxar.h"

@implementation RXRCacheFileRequestHandler

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
  return [request rxr_isCacheFileRequest];
}

- (BOOL)canHandleRequest:(NSURLRequest *)request originalRequest:(NSURLRequest *)originalRequest
{
  return [self.class canInitWithRequest:request];
}

- (NSURLRequest *)decoratedRequestOfRequest:(NSURLRequest *)request originalRequest:(NSURLRequest *)originalRequest
{
  return request;
}

@end
