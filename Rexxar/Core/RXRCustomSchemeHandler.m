//
//  RXRCustomSchemeHandler.m
//  Rexxar
//
//  Created by hao on 2020/5/21.
//

#import "RXRCustomSchemeHandler.h"
#import "RXRURLSessionDemux.h"
#import "RXRConfig+Rexxar.h"
#import "NSHTTPURLResponse+Rexxar.h"
#import "NSURL+Rexxar.h"

API_AVAILABLE(ios(11.0))
@protocol RXRCustomSchemeRunnerDelegate <NSObject>

@optional
- (void)schemeTask:(id <WKURLSchemeTask>)task didCompleteWithError:(nullable NSError *)error;

@end


API_AVAILABLE(ios(11.0))
@interface RXRCustomSchemeDataTaskRunner: NSObject <NSURLSessionDataDelegate>

@property (nonatomic, strong) id <WKURLSchemeTask> schemeTask;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property(nonatomic, strong) RXRURLSessionDemux *sessionDemux;

@property (nonatomic, weak) id<RXRCustomSchemeRunnerDelegate> delegate;

@property (nonatomic, assign) BOOL hasReceiveResponse;

@end

@implementation RXRCustomSchemeDataTaskRunner

- (instancetype)initWithSchemeTask:(id <WKURLSchemeTask>)schemeTask sessionDemux:(RXRURLSessionDemux *)sessionDemux
{
  self = [super init];
  if (self) {
    _sessionDemux = sessionDemux;
    _schemeTask = schemeTask;

    NSMutableURLRequest *request = [schemeTask.request mutableCopy];
    if ([request.URL rxr_isRexxarHttpScheme]) {
      request.URL = [request.URL rxr_urlByReplacingRexxarSchemeWithHttp];
    }

    NSMutableArray *modes = [NSMutableArray array];
    [modes addObject:NSDefaultRunLoopMode];
    NSString *currentMode = [[NSRunLoop currentRunLoop] currentMode];
    if (currentMode != nil && ![currentMode isEqualToString:NSDefaultRunLoopMode]) {
      [modes addObject:currentMode];
    }
    _dataTask = [sessionDemux dataTaskWithRequest:request delegate:self modes:modes];
  }
  return self;
}

- (void)resume
{
  [self.dataTask resume];
}

- (void)cancel
{
  [self.sessionDemux performBlockWithTask:self.dataTask block:^{
    self.schemeTask = nil;
    [self.dataTask cancel];
  }];
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
  if (self.hasReceiveResponse) {
    NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:nil];
    RXRLogObject *logObj = [[RXRLogObject alloc] initWithLogDescription:@"rxr_already_receive_response" error:error requestURL:dataTask.currentRequest.URL localFilePath:nil otherInformation:nil];
    [RXRConfig rxr_logWithLogObject:logObj];
    return;
  }
  NSHTTPURLResponse *URLResponse = nil;
  if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
    URLResponse = (NSHTTPURLResponse *)response;
    URLResponse = [NSHTTPURLResponse rxr_responseWithURL:self.schemeTask.request.URL
                                              statusCode:URLResponse.statusCode
                                            headerFields:URLResponse.allHeaderFields
                                         noAccessControl:YES];
  }

  [self.schemeTask didReceiveResponse:URLResponse ?: response];
  completionHandler(NSURLSessionResponseAllow);
  self.hasReceiveResponse = YES;
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
  if (!self.hasReceiveResponse) {
    NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:nil];
    RXRLogObject *logObj = [[RXRLogObject alloc] initWithLogDescription:@"rxr_receive_data_before_response" error:error requestURL:dataTask.currentRequest.URL localFilePath:nil otherInformation:nil];
    [RXRConfig rxr_logWithLogObject:logObj];
    return;
  }

  [self.schemeTask didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *_Nullable cachedResponse))completionHandler
{
  completionHandler(proposedResponse);
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *_Nullable))completionHandler
{
  NSMutableURLRequest *mutableRequest = [task.currentRequest mutableCopy];
  [mutableRequest setURL:request.URL];
  completionHandler(mutableRequest);
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
  if (error == nil && !self.hasReceiveResponse) {
    error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:nil];
    RXRLogObject *logObj = [[RXRLogObject alloc] initWithLogDescription:@"rxr_finish_before_response" error:error requestURL:task.currentRequest.URL localFilePath:nil otherInformation:nil];
    [RXRConfig rxr_logWithLogObject:logObj];
  }

  if (error == nil) {
    [self.schemeTask didFinish];
  } else {
    if ([error.domain isEqual:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
      // Do nothing.
    } else {
      [self.schemeTask didFailWithError:error];
    }
  }

  if ([self.delegate respondsToSelector:@selector(schemeTask:didCompleteWithError:)]) {
    [self.delegate schemeTask:self.schemeTask didCompleteWithError:error];
  }
}

@end

API_AVAILABLE(ios(11.0))
@interface RXRCustomSchemeHandler() <RXRCustomSchemeRunnerDelegate>

@property(nonatomic, strong) NSMutableDictionary<NSString *, RXRCustomSchemeDataTaskRunner *> *runningTasks;
@property(nonatomic, strong) dispatch_semaphore_t listSema;
@property(nonatomic, strong) RXRURLSessionDemux *sessionDemux;

@end

@implementation RXRCustomSchemeHandler

- (instancetype)init
{
  self = [super init];
  if (self) {
    _runningTasks = [NSMutableDictionary dictionary];
    _listSema = dispatch_semaphore_create(1);

    NSURLSessionConfiguration *sessionConfiguration = [RXRConfig requestsURLSessionConfiguration];
    _sessionDemux = [[RXRURLSessionDemux alloc] initWithSessionConfiguration:sessionConfiguration];
  }
  return self;
}

- (void)webView:(WKWebView *)webView startURLSchemeTask:(id <WKURLSchemeTask>)urlSchemeTask API_AVAILABLE(ios(11.0))
{
  RXRCustomSchemeDataTaskRunner *runner = [[RXRCustomSchemeDataTaskRunner alloc] initWithSchemeTask:urlSchemeTask sessionDemux:self.sessionDemux];
  runner.delegate = self;
  NSString *taskID = [self taskIDForSchemeTask:urlSchemeTask];
  dispatch_semaphore_wait(self.listSema, DISPATCH_TIME_FOREVER);
  self.runningTasks[taskID] = runner;
  dispatch_semaphore_signal(self.listSema);
  [runner resume];
}

- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id <WKURLSchemeTask>)urlSchemeTask API_AVAILABLE(ios(11.0))
{
  NSString *taskID = [self taskIDForSchemeTask:urlSchemeTask];
  dispatch_semaphore_wait(self.listSema, DISPATCH_TIME_FOREVER);
  [self.runningTasks[taskID] cancel];
  self.runningTasks[taskID] = nil;
  dispatch_semaphore_signal(self.listSema);
}

- (NSString *)taskIDForSchemeTask:(id <WKURLSchemeTask>)urlSchemeTask API_AVAILABLE(ios(11.0))
{
  return [NSString stringWithFormat:@"%p", urlSchemeTask];
}

- (void)schemeTask:(id<WKURLSchemeTask>)task didCompleteWithError:(NSError *)error
{
  NSString *taskID = [self taskIDForSchemeTask:task];
  dispatch_semaphore_wait(self.listSema, DISPATCH_TIME_FOREVER);
  self.runningTasks[taskID] = nil;
  dispatch_semaphore_signal(self.listSema);
}

@end
