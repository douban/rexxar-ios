//
//  RXRCacheFileResponseHandler.m
//  MTURLProtocol
//
//  Created by bigyelow on 2018/8/23.
//

#import "RXRCacheFileResponseHandler.h"
#import "NSURLRequest+Rexxar.h"
#import "NSHTTPURLResponse+Rexxar.h"
#import "RXRRouteFileCache.h"

@interface RXRCacheFileResponseHandler ()

@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, copy) NSString *responseDataFilePath;

@end

@implementation RXRCacheFileResponseHandler

- (BOOL)shouldHandleRequest:(NSURLRequest *)request originalRequest:(nonnull NSURLRequest *)originalRequest
{
  return [originalRequest rxr_isCacheFileRequest];
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(nonnull NSHTTPURLResponse *)response
        newRequest:(nonnull NSURLRequest *)request
 completionHandler:(nonnull void (^)(NSURLRequest * _Nullable))completionHandler
{
  if (self.client != nil && self.dataTask == task) {
    [self.client URLProtocol:self.protocol wasRedirectedToRequest:request redirectResponse:response];

    NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
    [self.dataTask cancel];
    [self.client URLProtocol:self.protocol didFailWithError:error];
  }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
  NSURLRequest *request = dataTask.currentRequest;

  if (![request.URL isFileURL] &&
      [request rxr_isCacheFileRequest] &&
      [[self class] _rxr_isCacheableResponse:response]) {
    self.responseDataFilePath = [self _rxr_temporaryFilePath];
    [[NSFileManager defaultManager] createFileAtPath:self.responseDataFilePath contents:nil attributes:nil];
    self.fileHandle = nil;
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.responseDataFilePath];
  }

  NSHTTPURLResponse *URLResponse = nil;
  if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
    URLResponse = (NSHTTPURLResponse *)response;
    URLResponse = [NSHTTPURLResponse rxr_responseWithURL:URLResponse.URL
                                              statusCode:URLResponse.statusCode
                                            headerFields:URLResponse.allHeaderFields
                                         noAccessControl:YES];
  }
  [self.client URLProtocol:self.protocol
        didReceiveResponse:URLResponse ?: response
        cacheStoragePolicy:NSURLCacheStorageNotAllowed];
  completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
  if ([dataTask.currentRequest rxr_isCacheFileRequest] && self.fileHandle) {
    [self.fileHandle writeData:data];
  }
  [self.client URLProtocol:self.protocol didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
  if (self.client != nil && (self.dataTask == nil || self.dataTask == task)) {
    if (error == nil) {
      if ([task.currentRequest rxr_isCacheFileRequest] && self.fileHandle) {
        [self.fileHandle closeFile];
        self.fileHandle = nil;
        NSData *data = [NSData dataWithContentsOfFile:self.responseDataFilePath];
        [[RXRRouteFileCache sharedInstance] saveRouteFileData:data withRemoteURL:task.currentRequest.URL];
      }
      [self.client URLProtocolDidFinishLoading:self.protocol];
    } else {
      if ([task.currentRequest rxr_isCacheFileRequest] && self.fileHandle) {
        [self.fileHandle closeFile];
        self.fileHandle = nil;
        [[NSFileManager defaultManager] removeItemAtPath:self.responseDataFilePath error:nil];
      }

      if ([error.domain isEqual:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
        // Do nothing.
      } else {
        [self.client URLProtocol:self.protocol didFailWithError:error];
      }
    }
  }
}

#pragma mark - Helpers

+ (BOOL)_rxr_isCacheableResponse:(NSURLResponse *)response
{
  NSSet *cacheableTypes = [NSSet setWithObjects:@"application/javascript",
                           @"application/x-javascript",
                           @"text/javascript",
                           @"text/css",
                           @"text/html", nil];
  return [cacheableTypes containsObject:response.MIMEType];
}

- (NSString *)_rxr_temporaryFilePath
{
  NSString *fileName = [[NSUUID UUID] UUIDString];
  return [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
}

@end
