//
//  RXRCacheFileInterceptor.m
//  Rexxar
//
//  Created by Tony Li on 11/4/15.
//  Copyright © 2015 Douban Inc. All rights reserved.
//

#import "RXRCacheFileInterceptor.h"
#import "RXRRouteFileCache.h"
#import "RXRLogging.h"
#import "NSURL+Rexxar.h"

static NSString * const RXRCacheFileIntercepterHandledKey = @"RXRCacheFileIntercepterHandledKey";
static NSInteger sRegisterInterceptorCounter;

@interface RXRCacheFileInterceptor () <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionTask *dataTask;
@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, strong) NSString *responseDataFilePath;

@end


@implementation RXRCacheFileInterceptor

+ (BOOL)registerInterceptor
{
  __block BOOL result;
  dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_barrier_sync(globalQueue, ^{

    if (sRegisterInterceptorCounter <= 0) {
      result = [NSURLProtocol registerClass:[self class]];
      if (result) {
        sRegisterInterceptorCounter = 1;
      }
    } else {
      sRegisterInterceptorCounter++;
      result = YES;
    }

  });

  return result;
}

+ (void)unregisterInterceptor
{
  dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_barrier_async(globalQueue, ^{
    sRegisterInterceptorCounter--;
    if (sRegisterInterceptorCounter < 0) {
      sRegisterInterceptorCounter = 0;
    }

    if (sRegisterInterceptorCounter == 0) {
      [NSURLProtocol unregisterClass:[self class]];
    }
  });
}


#pragma mark - NSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
  // 不是 HTTP 请求，不处理
  if (![request.URL rxr_isHttpOrHttps]) {
    return NO;
  }
  // 请求被忽略（被标记为忽略或者已经请求过），不处理
  if ([self isRequestIgnored:request]) {
    return NO;
  }
  // 请求不是来自浏览器，不处理
  if (![request.allHTTPHeaderFields[@"User-Agent"] hasPrefix:@"Mozilla"]) {
    return NO;
  }

  // 如果请求不需要被拦截，不处理
  if (![self shouldInterceptRequest:request]) {
    return NO;
  }

  return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
  return request;
}

- (void)startLoading
{
  NSParameterAssert(self.dataTask == nil);
  NSParameterAssert([[self class] canInitWithRequest:self.request]);

  RXRDebugLog(@"Intercept <%@> within <%@>", self.request.URL, self.request.mainDocumentURL);

  __block NSMutableURLRequest *request = nil;
  if ([self.request isKindOfClass:[NSMutableURLRequest class]]) {
    request = (NSMutableURLRequest *)self.request;
  } else {
    request = [self.request mutableCopy];
  }

  NSURL *localURL = [self _rxr_localFileURL:request.URL];
  if (localURL) {
    request.URL = localURL;
  }

  [[self class] markRequestAsIgnored:request];

  NSURLSessionTask *dataTask = [self.session dataTaskWithRequest:request];
  [dataTask resume];
  [self setDataTask:dataTask];
}

- (void)stopLoading
{
  if (self.dataTask != nil) {
    [self.dataTask cancel];
    [self setDataTask:nil];
  }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(nonnull NSHTTPURLResponse *)response
        newRequest:(nonnull NSURLRequest *)request
 completionHandler:(nonnull void (^)(NSURLRequest * _Nullable))completionHandler
{
  if (self.client != nil && self.dataTask == task) {
    [self.client URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
    completionHandler(request);
  }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
  if ([[self class] _rxr_isCacheableResponse:response]) {
    self.responseDataFilePath = [self _rxr_temporaryFilePath];
    [[NSFileManager defaultManager] createFileAtPath:self.responseDataFilePath contents:nil attributes:nil];
    self.fileHandle = nil;
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.responseDataFilePath];
  }

  [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
  completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
  if (self.fileHandle != nil) {
    [self.fileHandle writeData:data];
  }
  [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
  if (self.client != nil && self.dataTask == task) {
    if (error == nil) {
      if ([[self class] shouldInterceptRequest:task.currentRequest] && self.fileHandle) {
        [self.fileHandle closeFile];
        self.fileHandle = nil;
        NSData *data = [NSData dataWithContentsOfFile:self.responseDataFilePath];
        [[RXRRouteFileCache sharedInstance] saveRouteFileData:data withRemoteURL:task.currentRequest.URL];
        [self.client URLProtocolDidFinishLoading:self];
      }
    } else {
      if ([[self class] shouldInterceptRequest:task.currentRequest] && self.fileHandle) {
        [self.fileHandle closeFile];
        self.fileHandle = nil;
        [[NSFileManager defaultManager] removeItemAtPath:self.responseDataFilePath error:nil];
      }
      [self.client URLProtocol:self didFailWithError:error];
    }
  }
}

#pragma mark - Init

- (instancetype)initWithRequest:(NSURLRequest *)request
                 cachedResponse:(nullable NSCachedURLResponse *)cachedResponse
                         client:(nullable id <NSURLProtocolClient>)client
{
  self = [super initWithRequest:request cachedResponse:cachedResponse client:client];
  if (self != nil) {
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];

    NSOperationQueue *delegateQueue = [[NSOperationQueue alloc] init];
    delegateQueue.maxConcurrentOperationCount = 1;

    _session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:delegateQueue];
  }
  return self;
}

#pragma mark - Public methods

+ (BOOL)shouldInterceptRequest:(NSURLRequest *)request
{
  NSString *extension = request.URL.pathExtension;
  if ([extension isEqualToString:@"js"] ||
      [extension isEqualToString:@"css"]) {
    return YES;
  }
  return NO;
}

+ (void)markRequestAsIgnored:(NSMutableURLRequest *)request
{
  [NSURLProtocol setProperty:@YES forKey:RXRCacheFileIntercepterHandledKey inRequest:request];
}

+ (BOOL)isRequestIgnored:(NSURLRequest *)request
{
  if ([NSURLProtocol propertyForKey:RXRCacheFileIntercepterHandledKey inRequest:request]) {
    return YES;
  }
  return NO;
}

#pragma mark - Private methods

- (NSURL *)_rxr_localFileURL:(NSURL *)remoteURL
{
  NSURL *URL = [[NSURL alloc] initWithScheme:[remoteURL scheme]
                                        host:[remoteURL host]
                                        path:[remoteURL path]];
  NSURL *localURL = [[RXRRouteFileCache sharedInstance] routeFileURLForRemoteURL:URL];
  return localURL;
}

+ (BOOL)_rxr_isCacheableResponse:(NSURLResponse *)response
{
  NSSet *cacheableTypes = [NSSet setWithObjects:@"application/javascript", @"application/x-javascript",
                           @"text/javascript", @"text/css", nil];
  return [cacheableTypes containsObject:response.MIMEType];
}

- (NSString *)_rxr_temporaryFilePath
{
  NSString *fileName = [[NSUUID UUID] UUIDString];
  return [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
}

@end
