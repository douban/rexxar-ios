//
//  RXRNSURLProtocol.m
//  Rexxar
//
//  Created by GUO Lin on 5/17/16.
//  Copyright © 2016 Douban Inc. All rights reserved.
//

#import "RXRNSURLProtocol.h"
#import "RXRConfig.h"
#import "RXRConfig+Rexxar.h"
#import "RXRURLSessionDemux.h"
#import "NSHTTPURLResponse+Rexxar.h"
#import "RXRErrorHandler.h"

static NSMutableDictionary *sRegisteredClassCounter;

@implementation RXRNSURLProtocol

+ (RXRURLSessionDemux *)sharedDemux
{
  static dispatch_once_t onceToken;
  static RXRURLSessionDemux *demux;

  dispatch_once(&onceToken, ^{
    NSURLSessionConfiguration *sessionConfiguration = [RXRConfig requestsURLSessionConfiguration];
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

  BOOL result;
  NSInteger countForClass = [self _rxr_countForRegisteredClass:clazz];
  if (countForClass <= 0) {
    result = [NSURLProtocol registerClass:clazz];
    if (result) {
      [self _rxr_setCount:1 forRegisteredClass:clazz];
    }
  } else {
    [self _rxr_setCount:countForClass + 1 forRegisteredClass:clazz];
    result = YES;
  }

  return result;
}

+ (void)unregisterRXRProtocolClass:(Class)clazz
{
  NSParameterAssert([clazz isSubclassOfClass:[self class]]);

  NSInteger countForClass = [self _rxr_countForRegisteredClass:clazz] - 1;
  if (countForClass <= 0) {
    [NSURLProtocol unregisterClass:clazz];
  }

  if (countForClass >= 0) {
    [self _rxr_setCount:countForClass forRegisteredClass:clazz];
  }
}

#pragma mark - Private methods

+ (NSInteger)_rxr_countForRegisteredClass:(Class)clazz
{
  NSString *key = NSStringFromClass(clazz);
  if (key && sRegisteredClassCounter && sRegisteredClassCounter[key]) {
    return [sRegisteredClassCounter[key] integerValue];
  }

  return 0;
}

+ (void)_rxr_setCount:(NSInteger)count forRegisteredClass:(Class)clazz
{
  if (!sRegisteredClassCounter) {
    sRegisteredClassCounter = [NSMutableDictionary dictionary];
  }

  NSString *key = NSStringFromClass(clazz);
  if (key) {
    sRegisteredClassCounter[key] = @(count);
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
      // Here we don't call `URLProtocol:didFailWithError:` method because browser may not be able to handle `error`
      // object correctly. Instead we return HTTP response manually and you can handle this response easily
      // in rexxar-web (https://github.com/douban/rexxar-web). In addition, we alse leave chance for
      // native code to handle the error through `rxr_handleError:fromReporter:` method.
      NSHTTPURLResponse *response = [NSHTTPURLResponse rxr_responseWithURL:task.currentRequest.URL
                                                                statusCode:rxrHttpResponseURLProtocolError
                                                              headerFields:nil
                                                           noAccessControl:YES];

      [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];

      if ([RXRConfig rxr_canHandleError]) {
        [RXRConfig rxr_handleError:error fromReporter:self];
      }
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
