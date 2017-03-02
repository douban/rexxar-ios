//
//  RXRNSURLProtocol.m
//  Rexxar
//
//  Created by GUO Lin on 5/17/16.
//  Copyright © 2016 Douban Inc. All rights reserved.
//

#import "RXRNSURLProtocol.h"
#import "NSURLResponse+Rexxar.h"

@implementation RXRNSURLProtocol

- (instancetype)initWithRequest:(NSURLRequest *)request
                 cachedResponse:(nullable NSCachedURLResponse *)cachedResponse
                         client:(nullable id <NSURLProtocolClient>)client
{
  self = [super initWithRequest:request cachedResponse:cachedResponse client:client];
  if (self != nil) {
    NSURLSessionConfiguration *URLSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    URLSessionConfiguration.protocolClasses = @[[self class]];

    NSOperationQueue *delegateQueue = [[NSOperationQueue alloc] init];
    [delegateQueue setMaxConcurrentOperationCount:1];

    _URLSession = [NSURLSession sessionWithConfiguration:URLSessionConfiguration delegate:self delegateQueue:delegateQueue];
  }

  return self;
}

- (void)stopLoading
{
  if ([self dataTask] != nil) {
    [[self dataTask] cancel];
    [self setDataTask:nil];
  }
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
  return request;
}

+ (void)markRequestAsIgnored:(NSMutableURLRequest *)request
{
  NSString *key = NSStringFromClass([self class]);
  [NSURLProtocol setProperty:@YES forKey:key inRequest:request];
}

+ (BOOL)isRequestIgnored:(NSURLRequest *)request
{
  NSString *key = NSStringFromClass([self class]);
  if ([NSURLProtocol propertyForKey:key inRequest:request]) {
    return YES;
  }
  return NO;
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *_Nullable))completionHandler
{
  if ([self client] != nil && [self dataTask] == task) {
    [[self client] URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
    completionHandler(request);
  }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
  if ([self client] != nil && [self dataTask] == task) {
    if (error == nil) {
      [[self client] URLProtocolDidFinishLoading:self];
    } else {
      [[self client] URLProtocol:self didFailWithError:error];
    }
  }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
  if ([self client] != nil && [self dataTask] != nil && [self dataTask] == dataTask) {
    NSURLResponse *URLResponse = [NSURLResponse rxr_noAccessControlHeaderInstanceWithResponse:response];
    [[self client] URLProtocol:self
            didReceiveResponse:URLResponse
            cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
  }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
  if ([self client] != nil && [self dataTask] == dataTask) {
    [[self client] URLProtocol:self didLoadData:data];
  }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *_Nullable cachedResponse))completionHandler
{
  if ([self client] != nil && [self dataTask] == dataTask) {
    completionHandler(proposedResponse);
  }
}

@end
