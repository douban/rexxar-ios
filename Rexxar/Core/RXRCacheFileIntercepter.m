//
//  RXRCacheFileIntercepter.m
//  Rexxar
//
//  Created by Tony Li on 11/4/15.
//  Copyright © 2015 Douban Inc. All rights reserved.
//

#import "RXRCacheFileIntercepter.h"

#import "RXRRouteFileCache.h"

#import "RXRLogging.h"
#import "NSURL+Rexxar.h"

static NSString * const RXRCacheFileIntercepterHandledKey = @"RXRCacheFileIntercepterHandledKey";

@interface RXRCacheFileIntercepter ()

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, strong) NSString *responseDataFilePath;

@end


@implementation RXRCacheFileIntercepter

#pragma mark - NSURLProtocol's methods

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
  NSParameterAssert(self.connection == nil);
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
  self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

- (void)stopLoading
{
  [self.connection cancel];
}

#pragma mark - NSURLConnectionDataDelegate' methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  NSURLRequest *request = connection.currentRequest;

  if (![request.URL isFileURL] &&
      [[self class] shouldInterceptRequest:request] &&
      [[self class] _rxr_isCacheableResponse:response]) {

    self.responseDataFilePath = [self _rxr_temporaryFilePath];
    [[NSFileManager defaultManager] createFileAtPath:self.responseDataFilePath contents:nil attributes:nil];
    self.fileHandle = nil;
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.responseDataFilePath];
  }
  
  [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  if ([[self class] shouldInterceptRequest:connection.currentRequest] && self.fileHandle) {
    [self.fileHandle writeData:data];
  }
 [self.client URLProtocol:self didLoadData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  if ([[self class] shouldInterceptRequest:connection.currentRequest] && self.fileHandle) {
    [self.fileHandle closeFile];
    self.fileHandle = nil;
    NSData *data = [NSData dataWithContentsOfFile:self.responseDataFilePath];
    [[RXRRouteFileCache sharedInstance] saveRouteFileData:data withRemoteURL:connection.currentRequest.URL];
  }
  [self.client URLProtocolDidFinishLoading:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
  if ([[self class] shouldInterceptRequest:connection.currentRequest] && self.fileHandle) {
    [self.fileHandle closeFile];
    self.fileHandle = nil;
    [[NSFileManager defaultManager] removeItemAtPath:self.responseDataFilePath error:nil];
  }
  [self.client URLProtocol:self didFailWithError:error];
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
  NSSet *cachableTypes = [NSSet setWithObjects:@"application/javascript", @"application/x-javascript",
                          @"text/javascript", @"text/css", nil];
  return [cachableTypes containsObject:response.MIMEType];
}

- (NSString *)_rxr_temporaryFilePath
{
  NSString *fileName = [[NSUUID UUID] UUIDString];
  return [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
}

@end
