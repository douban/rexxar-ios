//
//  RXRURLSessionDemux.m
//  Rexxar
//
//  Created by XueMing on 31/03/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

#import "RXRURLSessionDemux.h"

@interface RXRURLSessionDemuxTask : NSObject

- (instancetype)initWithTask:(NSURLSessionDataTask *)task delegate:(id<NSURLSessionDataDelegate>)delegate modes:(NSArray *)modes;

@property (nonatomic, strong, readonly) NSURLSessionDataTask *task;
@property (nonatomic, weak, readonly) id<NSURLSessionDataDelegate> delegate;
@property (nonatomic, strong, readonly) NSThread *thread;
@property (nonatomic, copy, readonly) NSArray *modes;

- (void)performBlock:(dispatch_block_t)block;
- (void)invalidate;

@end

@interface RXRURLSessionDemuxTask ()

@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, weak) id<NSURLSessionDataDelegate> delegate;
@property (nonatomic, strong) NSThread *thread;
@property (nonatomic, copy) NSArray *modes;

@end

@implementation RXRURLSessionDemuxTask

- (instancetype)initWithTask:(NSURLSessionDataTask *)task delegate:(id<NSURLSessionDataDelegate>)delegate modes:(NSArray *)modes
{
  self = [super init];
  if (self != nil) {
    _task = task;
    _delegate = delegate;
    _thread = [NSThread currentThread];
    _modes = [modes copy];
  }
  return self;
}

- (void)performBlock:(dispatch_block_t)block
{
  NSAssert(_delegate != nil, nil);
  NSAssert(_thread != nil, nil);

  if (_delegate != nil && _thread != nil) {
    [self performSelector:@selector(performBlockOnClientThread:) onThread:_thread withObject:[block copy] waitUntilDone:NO modes:_modes];
  }
}

- (void)performBlockOnClientThread:(dispatch_block_t)block
{
  NSAssert([NSThread currentThread] == _thread, nil);
  block();
}

- (void)invalidate
{
  _delegate = nil;
  _thread = nil;
}

@end


@interface RXRURLSessionDemux () <NSURLSessionDataDelegate>

@property (nonatomic, copy  ) NSURLSessionConfiguration *sessionConfiguration;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOperationQueue *sessionDelegateQueue;
@property (nonatomic, strong) NSMutableDictionary *demuxTasks;

@end

@implementation RXRURLSessionDemux

- (instancetype)init
{
  return [self initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration
{
  self = [super init];
  if (self) {
    NSString *sessionName = [NSString stringWithFormat:@"%@.%@.%p.URLSession", [[NSBundle mainBundle] bundleIdentifier], NSStringFromClass([self class]), self];
    NSString *delegateQueueName = [NSString stringWithFormat:@"%@.delegateQueue", sessionName];

    _sessionConfiguration = [sessionConfiguration copy];
    _demuxTasks = [NSMutableDictionary dictionary];
    _sessionDelegateQueue = [[NSOperationQueue alloc] init];
    _sessionDelegateQueue.maxConcurrentOperationCount = 1;
    _sessionDelegateQueue.name = delegateQueueName;
    _session = [NSURLSession sessionWithConfiguration:_sessionConfiguration delegate:self delegateQueue:_sessionDelegateQueue];
    _session.sessionDescription = sessionName;
  }
  return self;
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                                     delegate:(id<NSURLSessionDataDelegate>)delegate
                                        modes:(nullable NSArray *)modes
{
  if ([modes count] == 0) {
    modes = @[NSDefaultRunLoopMode];
  }

  NSURLSessionDataTask *dataTask = [_session dataTaskWithRequest:request];
  RXRURLSessionDemuxTask *demuxTask = [[RXRURLSessionDemuxTask alloc] initWithTask:dataTask delegate:delegate modes:modes];

  @synchronized (self) {
    _demuxTasks[@([dataTask taskIdentifier])] = demuxTask;
  }

  return dataTask;
}

- (RXRURLSessionDemuxTask *)demuxTaskForTask:(NSURLSessionTask *)task
{
  RXRURLSessionDemuxTask *demuxTask = nil;

  @synchronized (self) {
    demuxTask = [self.demuxTasks objectForKey:@([task taskIdentifier])];
  }

  return demuxTask;
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)newRequest
 completionHandler:(void (^)(NSURLRequest *))completionHandler
{
  RXRURLSessionDemuxTask *demuxTask = [self demuxTaskForTask:task];

  if ([demuxTask.delegate respondsToSelector:@selector(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:)]) {
    [demuxTask performBlock:^{
      [demuxTask.delegate URLSession:session task:task willPerformHTTPRedirection:response newRequest:newRequest completionHandler:completionHandler];
    }];
  } else {
    completionHandler(newRequest);
  }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
  RXRURLSessionDemuxTask *demuxTask = [self demuxTaskForTask:task];

  if ([demuxTask.delegate respondsToSelector:@selector(URLSession:task:didReceiveChallenge:completionHandler:)]) {
    [demuxTask performBlock:^{
      [demuxTask.delegate URLSession:session task:task didReceiveChallenge:challenge completionHandler:completionHandler];
    }];
  } else {
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
  }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
 needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler
{
  RXRURLSessionDemuxTask *demuxTask = [self demuxTaskForTask:task];

  if ([demuxTask.delegate respondsToSelector:@selector(URLSession:task:needNewBodyStream:)]) {
    [demuxTask performBlock:^{
      [demuxTask.delegate URLSession:session task:task needNewBodyStream:completionHandler];
    }];
  } else {
    completionHandler(nil);
  }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
  RXRURLSessionDemuxTask *demuxTask = [self demuxTaskForTask:task];

  if ([demuxTask.delegate respondsToSelector:@selector(URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)]) {
    [demuxTask performBlock:^{
      [demuxTask.delegate URLSession:session task:task didSendBodyData:bytesSent totalBytesSent:totalBytesSent totalBytesExpectedToSend:totalBytesExpectedToSend];
    }];
  }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
  RXRURLSessionDemuxTask *demuxTask = [self demuxTaskForTask:task];

  @synchronized (self) {
    [self.demuxTasks removeObjectForKey:@(demuxTask.task.taskIdentifier)];
  }

  // Call the delegate if required.  In that case we invalidate the task info on the client thread
  // after calling the delegate, otherwise the client thread side of the -performBlock: code can
  // find itself with an invalidated task info.

  if ([demuxTask.delegate respondsToSelector:@selector(URLSession:task:didCompleteWithError:)]) {
    [demuxTask performBlock:^{
      [demuxTask.delegate URLSession:session task:task didCompleteWithError:error];
      [demuxTask invalidate];
    }];
  } else {
    [demuxTask invalidate];
  }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
  RXRURLSessionDemuxTask *demuxTask = [self demuxTaskForTask:dataTask];

  if ([demuxTask.delegate respondsToSelector:@selector(URLSession:dataTask:didReceiveResponse:completionHandler:)]) {
    [demuxTask performBlock:^{
      [demuxTask.delegate URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
    }];
  } else {
    completionHandler(NSURLSessionResponseAllow);
  }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
  RXRURLSessionDemuxTask *demuxTask = [self demuxTaskForTask:dataTask];

  if ([demuxTask.delegate respondsToSelector:@selector(URLSession:dataTask:didBecomeDownloadTask:)]) {
    [demuxTask performBlock:^{
      [demuxTask.delegate URLSession:session dataTask:dataTask didBecomeDownloadTask:downloadTask];
    }];
  }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
  RXRURLSessionDemuxTask *demuxTask = [self demuxTaskForTask:dataTask];

  if ([demuxTask.delegate respondsToSelector:@selector(URLSession:dataTask:didReceiveData:)]) {
    [demuxTask performBlock:^{
      [demuxTask.delegate URLSession:session dataTask:dataTask didReceiveData:data];
    }];
  }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler
{
  RXRURLSessionDemuxTask *demuxTask = [self demuxTaskForTask:dataTask];

  if ([demuxTask.delegate respondsToSelector:@selector(URLSession:dataTask:willCacheResponse:completionHandler:)]) {
    [demuxTask performBlock:^{
      [demuxTask.delegate URLSession:session dataTask:dataTask willCacheResponse:proposedResponse completionHandler:completionHandler];
    }];
  } else {
    completionHandler(proposedResponse);
  }
}

@end
