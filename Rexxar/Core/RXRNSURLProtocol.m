//
//  RXRNSURLProtocol.m
//  Rexxar
//
//  Created by GUO Lin on 5/17/16.
//  Copyright © 2016 Douban Inc. All rights reserved.
//

#import "RXRNSURLProtocol.h"
#import "RXRURLSessionDemux.h"
#import "NSHTTPURLResponse+Rexxar.h"

static NSDictionary *sRegisteredClassCounter;

@implementation RXRNSURLProtocol

+ (RXRURLSessionDemux *)sharedDemux
{
  static dispatch_once_t onceToken;
  static RXRURLSessionDemux *demux;

  dispatch_once(&onceToken, ^{
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    demux = [[RXRURLSessionDemux alloc] initWithSessionConfiguration:sessionConfiguration];
  });

  return demux;
}

- (void)startLoading
{
  NSAssert(NO, @"Implement this method in a subclass.");
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

#pragma mark - Public methods, do not override

+ (void)markRequestAsIgnored:(NSMutableURLRequest *)request
{
  NSString *key = NSStringFromClass([self class]);
  [NSURLProtocol setProperty:@YES forKey:key inRequest:request];
}

+ (void)unmarkRequestAsIgnored:(NSMutableURLRequest *)request
{
  NSString *key = NSStringFromClass([self class]);
  [NSURLProtocol removePropertyForKey:key inRequest:request];
}

+ (BOOL)isRequestIgnored:(NSURLRequest *)request
{
  NSString *key = NSStringFromClass([self class]);
  if ([NSURLProtocol propertyForKey:key inRequest:request]) {
    return YES;
  }
  return NO;
}

+ (BOOL)registerRXRProtocolClass:(Class)clazz
{
  NSParameterAssert([clazz isSubclassOfClass:[self class]]);

  __block BOOL result;
  dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_barrier_sync(globalQueue, ^{
    NSInteger countForClass = [self _frd_countForRegisteredClass:clazz];
    if (countForClass <= 0) {
      result = [NSURLProtocol registerClass:clazz];
      if (result) {
        [self _frd_setCount:1 forRegisteredClass:clazz];
      }
    } else {
      [self _frd_setCount:countForClass + 1 forRegisteredClass:clazz];
      result = YES;
    }
  });

  return result;
}

+ (void)unregisterRXRProtocolClass:(Class)clazz
{
  NSParameterAssert([clazz isSubclassOfClass:[self class]]);

  dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_barrier_async(globalQueue, ^{

    NSInteger countForClass = [self _frd_countForRegisteredClass:clazz] - 1;
    if (countForClass < 0) {
      return;
    }
    if (countForClass == 0) {
      [NSURLProtocol unregisterClass:clazz];
    }
    [self _frd_setCount:countForClass forRegisteredClass:clazz];
  });
}

#pragma mark - Private methods

+ (NSInteger)_frd_countForRegisteredClass:(Class)clazz
{
  NSString *key = NSStringFromClass(clazz);
  if (key && sRegisteredClassCounter && sRegisteredClassCounter[key]) {
    return [sRegisteredClassCounter[key] integerValue];
  }
  else {
    return 0;
  }
}

+ (void)_frd_setCount:(NSInteger)count forRegisteredClass:(Class)clazz
{
  NSString *key = NSStringFromClass(clazz);
  NSMutableDictionary *mutDict = [sRegisteredClassCounter mutableCopy];
  if (key) {
    if (!mutDict) {
      mutDict = [NSMutableDictionary dictionary];
    }
    mutDict[key] = @(count);
  }
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *_Nullable))completionHandler
{
  if ([self client] != nil && [self dataTask] == task) {
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    [[self class] unmarkRequestAsIgnored:mutableRequest];
    [[self client] URLProtocol:self wasRedirectedToRequest:mutableRequest redirectResponse:response];

    NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
    [self.dataTask cancel];
    [self.client URLProtocol:self didFailWithError:error];
  }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
  if ([self client] != nil && (_dataTask == nil || _dataTask == task)) {
    if (error == nil) {
      [[self client] URLProtocolDidFinishLoading:self];
    } else if ([error.domain isEqual:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
      // Do nothing.
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
    NSHTTPURLResponse *URLResponse = nil;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
      URLResponse = (NSHTTPURLResponse *)response;
      URLResponse = [NSHTTPURLResponse rxr_responseWithURL:URLResponse.URL
                                                statusCode:URLResponse.statusCode
                                              headerFields:URLResponse.allHeaderFields
                                           noAccessControl:YES];
    }

    [[self client] URLProtocol:self
            didReceiveResponse:URLResponse ?: response
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
