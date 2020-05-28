//
//  RXRCustomSchemeHandler.m
//  Rexxar
//
//  Created by hao on 2020/5/21.
//

#import "RXRCustomSchemeHandler.h"
#import "RXRURLSessionDemux.h"
#import "RXRConfig.h"
#import "NSHTTPURLResponse+Rexxar.h"
#import "NSURL+Rexxar.h"

API_AVAILABLE(ios(11.0))
@interface RXRCustomSchemeDataTaskRunner: NSObject <NSURLSessionDataDelegate>

@property (nonatomic, strong) id <WKURLSchemeTask> schemeTask;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@end

@implementation RXRCustomSchemeDataTaskRunner

- (instancetype)initWithSchemeTask:(id <WKURLSchemeTask>)schemeTask sessionDemux:(RXRURLSessionDemux *)sessionDemux
{
  self = [super init];
  if (self) {
    _schemeTask = schemeTask;

    NSMutableURLRequest *request = [schemeTask.request mutableCopy];
    if ([request.URL rxr_isRexxarHttpScheme]) {
      request.URL = [request.URL rxr_urlByRemovingRexxarScheme];
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
  self.schemeTask = nil;
  [self.dataTask cancel];
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
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
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
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
  if (error == nil) {
    [self.schemeTask didFinish];
  } else {
    if ([error.domain isEqual:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
      // Do nothing.
    } else {
      [self.schemeTask didFailWithError:error];
    }
  }
}

@end

API_AVAILABLE(ios(11.0))
@interface RXRCustomSchemeHandler()

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

@end
