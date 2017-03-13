//
//  RXRNSURLProtocol.m
//  Rexxar
//
//  Created by GUO Lin on 5/17/16.
//  Copyright © 2016 Douban Inc. All rights reserved.
//

#import "RXRNSURLProtocol.h"
#import "NSHTTPURLResponse+Rexxar.h"

static NSDictionary *sRegisteredClassCounter;

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

- (void)startLoading
{
  NSURLSessionTask *dataTask = [[self URLSession] dataTaskWithRequest:self.request];
  [dataTask resume];
  [self setDataTask:dataTask];
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
