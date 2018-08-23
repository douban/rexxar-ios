//
//  RXRCacheFileLocalRequestHandler.m
//  MTURLProtocol
//
//  Created by bigyelow on 2018/8/23.
//

#import "RXRCacheFileLocalRequestHandler.h"
#import "NSURLRequest+Rexxar.h"
#import "NSHTTPURLResponse+Rexxar.h"
#import "RXRRouteFileCache.h"

@interface RXRCacheFileLocalRequestHandler ()

@property (nonatomic, copy) NSURL *localURL;

@end

@implementation RXRCacheFileLocalRequestHandler

- (BOOL)canInitWithRequest:(NSURLRequest *)request
{
  return [request rxr_isCacheFileRequest];
}

- (BOOL)canHandleRequest:(NSURLRequest *)request originalRequest:(NSURLRequest *)originalRequest
{
  self.localURL = [[self class] _rxr_localFileURL:request.URL];
  return _localURL != nil;
}

- (NSURLRequest *)decoratedRequestOfRequest:(NSURLRequest *)request originalRequest:(NSURLRequest *)originalRequest
{
  return request;
}

- (NSData *)responseData
{
  if (_localURL) {
    return [NSData dataWithContentsOfURL:_localURL];
  }
  return nil;
}

- (NSURLResponse *)responseForRequest:(NSURLRequest *)request
{
  NSHTTPURLResponse *response = [NSHTTPURLResponse rxr_responseWithURL:request.URL
                                                            statusCode:200
                                                          headerFields:nil
                                                       noAccessControl:YES];
  return response;
}

+ (NSURL *)_rxr_localFileURL:(NSURL *)remoteURL
{
  NSURL *URL = [[NSURL alloc] initWithScheme:[remoteURL scheme]
                                        host:[remoteURL host]
                                        path:[remoteURL path]];
  NSURL *localURL = [[RXRRouteFileCache sharedInstance] routeFileURLForRemoteURL:URL];
  return localURL;
}

@end
