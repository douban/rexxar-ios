#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "RXRConfig.h"
#import "RXRRoute.h"
#import "RXRRouteManager.h"
#import "RXRRouteFileCache.h"
#import "RXRCacheFileInterceptor.h"
#import "RXRViewController.h"
#import "NSData+RXRDigest.h"

@interface RXRRouteManager (PerformanceTests)
@property (nonatomic, copy) NSArray<RXRRoute *> *routes;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOperationQueue *sessionDelegateQueue;
- (void)_rxr_prefetchCommonUsedFilesWithinRoutes:(NSArray<RXRRoute *> *)routes;
@end

@interface RXRCountingValidator : NSObject <RXRDataValidator>
@property (atomic, assign) NSUInteger calls;
@property (atomic, assign) BOOL calledOnMain;
@property (atomic, assign) BOOL stopAfterInvalidData;
@property (atomic, assign) NSUInteger stopPolicyCalls;
@property (atomic, copy) void (^beforeValidation)(NSURL *);
@end

@implementation RXRCountingValidator
- (BOOL)validateRemoteHTMLFile:(NSURL *)url fileData:(NSData *)data
{
  @synchronized (self) {
    self.calls++;
    self.calledOnMain = self.calledOnMain || NSThread.isMainThread;
  }
  void (^beforeValidation)(NSURL *) = self.beforeValidation;
  if (beforeValidation) beforeValidation(url);
  NSString *hash = [[url.lastPathComponent stringByDeletingPathExtension] componentsSeparatedByString:@"-"].lastObject;
  return data.length > 0 && hash.length == 10 && [[data md5] hasPrefix:hash];
}
- (BOOL)stopDownloadingIfValidationFailed
{
  self.stopPolicyCalls++;
  return self.stopAfterInvalidData;
}
@end

@interface RXRPathCacheConverter : NSObject <RXRURLCacheConverter>
@end
@implementation RXRPathCacheConverter
- (NSString *)cacheKeyForURL:(NSURL *)url { return url.path; }
@end

@interface RXRPerformanceHTTPFixture : NSURLProtocol
@end

@implementation RXRPerformanceHTTPFixture
+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
  return [request.URL.host isEqualToString:@"cache-performance.invalid"];
}
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request { return request; }
- (void)startLoading
{
  if ([self.request.URL.lastPathComponent hasPrefix:@"pending-"]) return;
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:@{@"Content-Type": @"text/html"}];
  NSString *body = [self.request.URL.lastPathComponent hasPrefix:@"invalid-"] ? @"invalid" : @"<html><body>badge</body></html>";
  NSData *data = [body dataUsingEncoding:NSUTF8StringEncoding];
  [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
  [self.client URLProtocol:self didLoadData:data];
  [self.client URLProtocolDidFinishLoading:self];
}
- (void)stopLoading {}
@end

@interface RXRPerformanceSessionObserver : NSObject <NSURLSessionDelegate>
@property (nonatomic, strong) XCTestExpectation *finished;
@end

@implementation RXRPerformanceSessionObserver
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
  // The batch's main-queue cleanup is queued before this notification.
  dispatch_async(dispatch_get_main_queue(), ^{ [self.finished fulfill]; });
}
@end

@interface RXRRecordingViewController : RXRViewController
@property (nonatomic, strong) NSMutableArray<NSURLRequest *> *loadedRequests;
@property (nonatomic, copy) void (^didLoadRequest)(void);
@end

@implementation RXRRecordingViewController
- (void)loadRequest:(NSURLRequest *)request
{
  XCTAssertTrue(NSThread.isMainThread);
  if (!self.loadedRequests) self.loadedRequests = [NSMutableArray array];
  [self.loadedRequests addObject:request];
  if (self.didLoadRequest) self.didLoadRequest();
}
@end

@interface RXRCachePerformanceTests : XCTestCase
@property (nonatomic, strong) RXRRouteFileCache *cache;
@property (nonatomic, strong) RXRCountingValidator *validator;
@property (nonatomic, strong) id<RXRDataValidator> previousValidator;
@property (nonatomic, strong) id<RXRLogger> previousLogger;
@property (nonatomic, strong) id<RXRURLCacheConverter> previousCacheConverter;
@property (nonatomic, strong) NSURLSessionConfiguration *previousSessionConfiguration;
@property (nonatomic, copy) NSArray<RXRRoute *> *previousRoutes;
@property (nonatomic, copy) NSString *previousCachePath;
@property (nonatomic, copy) NSString *previousResourcePath;
@property (nonatomic, copy) NSString *temporaryDirectory;
@property (nonatomic, assign) BOOL previousCustomScheme;
@end

@implementation RXRCachePerformanceTests
- (void)setUp
{
  [super setUp];
  if (![RXRConfig routesResourcePath]) [RXRConfig setRoutesResourcePath:[NSBundle bundleForClass:self.class].bundlePath];
  self.cache = [RXRRouteFileCache sharedInstance];
  self.previousCachePath = self.cache.cachePath;
  self.previousResourcePath = self.cache.resourcePath;
  self.previousValidator = [RXRRouteManager sharedInstance].dataValidator;
  self.previousRoutes = [RXRRouteManager sharedInstance].routes;
  self.previousLogger = [RXRConfig logger];
  self.previousCacheConverter = [RXRConfig URLCacheConverter];
  self.previousCustomScheme = [RXRConfig useCustomScheme];
  self.previousSessionConfiguration = [RXRConfig requestsURLSessionConfiguration];
  [RXRConfig setLogger:nil];
  [RXRConfig setUseCustomScheme:YES];
  NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
  configuration.protocolClasses = @[RXRCacheFileInterceptor.class, RXRPerformanceHTTPFixture.class];
  [RXRConfig setRequestsURLSessionConfiguration:configuration];
  self.temporaryDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
  self.cache.cachePath = [self.temporaryDirectory stringByAppendingPathComponent:@"cache"];
  self.cache.resourcePath = [self.temporaryDirectory stringByAppendingPathComponent:@"bundle"];
  self.validator = [RXRCountingValidator new];
  [RXRRouteManager sharedInstance].dataValidator = self.validator;
}

- (void)tearDown
{
  self.validator.beforeValidation = nil;
  [self.cache cleanCache];
  self.cache.cachePath = self.previousCachePath;
  self.cache.resourcePath = self.previousResourcePath;
  [RXRRouteManager sharedInstance].dataValidator = self.previousValidator;
  [RXRRouteManager sharedInstance].routes = self.previousRoutes;
  [RXRConfig setLogger:self.previousLogger];
  [RXRConfig setURLCacheConverter:self.previousCacheConverter];
  [RXRConfig setUseCustomScheme:self.previousCustomScheme];
  [RXRConfig setRequestsURLSessionConfiguration:self.previousSessionConfiguration];
  [[NSFileManager defaultManager] removeItemAtPath:self.temporaryDirectory error:nil];
  [super tearDown];
}

- (NSData *)html { return [@"<html><body>badge</body></html>" dataUsingEncoding:NSUTF8StringEncoding]; }
- (NSURL *)htmlURL { return [NSURL URLWithString:@"https://cache-performance.invalid/pages/one-bcef9e511f.html"]; }
- (RXRRoute *)routeForURL:(NSURL *)url uri:(NSString *)uri
{
  return [[RXRRoute alloc] initWithDictionary:@{@"remote_file": url.absoluteString, @"uri": uri, @"pack_in_app": @YES}];
}
- (NSURL *)writeBundledHTML:(NSData *)data
{
  NSString *directory = [self.cache.resourcePath stringByAppendingPathComponent:@"pages"];
  XCTAssertTrue([[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil]);
  NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:self.htmlURL.lastPathComponent]];
  XCTAssertTrue([data writeToURL:url atomically:YES]);
  return url;
}

- (NSURL *)writeLegacyCachedHTML:(NSData *)data
{
  NSString *key = self.htmlURL.absoluteString;
  if ([RXRConfig URLCacheConverter]) key = [[RXRConfig URLCacheConverter] cacheKeyForURL:self.htmlURL];
  NSString *filename = [[[key dataUsingEncoding:NSUTF8StringEncoding] md5] stringByAppendingPathExtension:@"html"];
  NSURL *url = [NSURL fileURLWithPath:[self.cache.cachePath stringByAppendingPathComponent:filename]];
  XCTAssertTrue([data writeToURL:url atomically:YES]);
  return url;
}

- (void)testStoreValidatesOnceAndRepeatedLookupsReuseResult
{
  XCTAssertEqual([self.cache storeRouteFileData:self.html withRemoteURL:self.htmlURL], RXRRouteFileStoreResultSaved);
  XCTAssertEqual(self.validator.calls, 1u);
  for (NSUInteger index = 0; index < 5; index++) XCTAssertNotNil([self.cache routeFileURLForRemoteURL:self.htmlURL]);
  XCTAssertEqual(self.validator.calls, 1u);
}

- (void)testDiskWriteFailureIsNotValidationFailure
{
  NSString *blocker = [self.temporaryDirectory stringByAppendingPathComponent:@"not-a-directory"];
  XCTAssertTrue([self.html writeToFile:blocker atomically:YES]);
  self.cache.cachePath = [blocker stringByAppendingPathComponent:@"cache"];
  XCTAssertEqual([self.cache storeRouteFileData:self.html withRemoteURL:self.htmlURL], RXRRouteFileStoreResultWriteFailed);
  XCTAssertEqual(self.validator.calls, 1u);
}

- (void)testInvalidDownloadDoesNotReplaceValidCache
{
  [self.cache storeRouteFileData:self.html withRemoteURL:self.htmlURL];
  XCTAssertEqual([self.cache storeRouteFileData:[@"invalid" dataUsingEncoding:NSUTF8StringEncoding] withRemoteURL:self.htmlURL], RXRRouteFileStoreResultInvalidData);
  XCTAssertEqualObjects([self.cache routeFileDataForRemoteURL:self.htmlURL], self.html);
  XCTAssertEqual(self.validator.calls, 2u);
}

- (void)testLegacyCorruptCacheIsRejectedAndFallsBackToBundle
{
  NSURL *cachedURL = [self writeLegacyCachedHTML:[@"invalid" dataUsingEncoding:NSUTF8StringEncoding]];
  NSURL *bundledURL = [self writeBundledHTML:self.html];
  XCTAssertEqualObjects([self.cache routeFileURLForRemoteURL:self.htmlURL], bundledURL);
  XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:cachedURL.path]);
  XCTAssertEqual(self.validator.calls, 2u);
  XCTAssertNotNil([self.cache routeFileURLForRemoteURL:self.htmlURL]);
  XCTAssertEqual(self.validator.calls, 2u);
}

- (void)testValidatorChangeInvalidatesMemo
{
  [self.cache storeRouteFileData:self.html withRemoteURL:self.htmlURL];
  RXRCountingValidator *replacement = [RXRCountingValidator new];
  [RXRRouteManager sharedInstance].dataValidator = replacement;
  XCTAssertNotNil([self.cache routeFileURLForRemoteURL:self.htmlURL]);
  XCTAssertEqual(replacement.calls, 1u);
}

- (void)testRemovingCacheInvalidatesValidationMarker
{
  [self.cache storeRouteFileData:self.html withRemoteURL:self.htmlURL];
  [self.cache saveRouteFileData:nil withRemoteURL:self.htmlURL];
  [self writeLegacyCachedHTML:[@"invalid" dataUsingEncoding:NSUTF8StringEncoding]];
  XCTAssertNil([self.cache routeFileURLForRemoteURL:self.htmlURL]);
  XCTAssertEqual(self.validator.calls, 2u);
}

- (void)testConcurrentLegacyReadAndWriteLeaveValidCache
{
  [self writeLegacyCachedHTML:[@"invalid" dataUsingEncoding:NSUTF8StringEncoding]];
  XCTestExpectation *started = [self expectationWithDescription:@"Old file read started"];
  XCTestExpectation *readFinished = [self expectationWithDescription:@"Old file rejected"];
  XCTestExpectation *writeFinished = [self expectationWithDescription:@"Valid file written"];
  dispatch_semaphore_t releaseValidation = dispatch_semaphore_create(0);
  self.validator.beforeValidation = ^(NSURL *url) {
    [started fulfill];
    dispatch_semaphore_wait(releaseValidation, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));
  };
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    XCTAssertNil([self.cache routeFileURLForRemoteURL:self.htmlURL]);
    [readFinished fulfill];
  });
  [self waitForExpectations:@[started] timeout:5];
  self.validator.beforeValidation = nil;
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    XCTAssertEqual([self.cache storeRouteFileData:self.html withRemoteURL:self.htmlURL], RXRRouteFileStoreResultSaved);
    [writeFinished fulfill];
  });
  dispatch_semaphore_signal(releaseValidation);
  [self waitForExpectations:@[readFinished, writeFinished] timeout:5];
  XCTAssertEqualObjects([self.cache routeFileDataForRemoteURL:self.htmlURL], self.html);
  XCTAssertEqual(self.validator.calls, 2u);
}

- (void)testBundledLookupIsMemoizedAndDiskNamingIsUnchanged
{
  NSURL *bundledURL = [self writeBundledHTML:self.html];
  XCTAssertEqualObjects([self.cache routeFileURLForRemoteURL:self.htmlURL], bundledURL);
  XCTAssertEqualObjects([self.cache routeFileURLForRemoteURL:self.htmlURL], bundledURL);
  XCTAssertEqual(self.validator.calls, 1u);
  [self.cache storeRouteFileData:self.html withRemoteURL:self.htmlURL];
  NSString *filename = [[[self.htmlURL.absoluteString dataUsingEncoding:NSUTF8StringEncoding] md5] stringByAppendingPathExtension:@"html"];
  XCTAssertEqualObjects([self.cache routeFileURLForRemoteURL:self.htmlURL].lastPathComponent, filename);
}

- (void)testPathBasedCacheNamingStillIgnoresHostAndQuery
{
  [RXRConfig setURLCacheConverter:[RXRPathCacheConverter new]];
  [self.cache storeRouteFileData:self.html withRemoteURL:self.htmlURL];
  NSString *filename = [[[self.htmlURL.path dataUsingEncoding:NSUTF8StringEncoding] md5] stringByAppendingPathExtension:@"html"];
  NSURL *alias = [NSURL URLWithString:@"https://another-cdn.invalid/pages/one-bcef9e511f.html?version=2"];
  XCTAssertEqualObjects([self.cache routeFileURLForRemoteURL:alias].lastPathComponent, filename);
}

- (void)testOnDemandDownloadValidatesOnce
{
  NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
  configuration.protocolClasses = @[RXRCacheFileInterceptor.class, RXRPerformanceHTTPFixture.class];
  NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.htmlURL];
  [request setValue:@"Mozilla" forHTTPHeaderField:@"User-Agent"];
  XCTestExpectation *finished = [self expectationWithDescription:@"On-demand download"];
  [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    XCTAssertNil(error);
    XCTAssertEqualObjects(data, self.html);
    XCTAssertEqual(self.validator.calls, 1u);
    XCTAssertFalse(self.validator.calledOnMain);
    [finished fulfill];
  }] resume];
  [self waitForExpectationsWithTimeout:5 handler:nil];
  [session finishTasksAndInvalidate];
  XCTAssertNotNil([self.cache routeFileURLForRemoteURL:self.htmlURL]);
  XCTAssertEqual(self.validator.calls, 1u);
}

- (void)testPrefetchDownloadValidatesOnce
{
  [self finishPrefetchingURLs:@[self.htmlURL, self.htmlURL]];
  XCTAssertEqual(self.validator.calls, 1u);
  XCTAssertFalse(self.validator.calledOnMain);
  XCTAssertNotNil([self.cache routeFileURLForRemoteURL:self.htmlURL]);
  XCTAssertEqual(self.validator.calls, 1u);
}

- (void)testPrefetchDeduplicatesBeforeLookingUpCachedFiles
{
  [self.cache storeRouteFileData:self.html withRemoteURL:self.htmlURL];
  Method method = class_getInstanceMethod(RXRRouteFileCache.class, @selector(routeFileURLForRemoteURL:));
  IMP original = method_getImplementation(method);
  __block NSUInteger lookups = 0;
  IMP counting = imp_implementationWithBlock(^NSURL *(RXRRouteFileCache *cache, NSURL *url) {
    lookups++;
    return ((NSURL *(*)(id, SEL, NSURL *))original)(cache, @selector(routeFileURLForRemoteURL:), url);
  });
  method_setImplementation(method, counting);
  @try {
    RXRRoute *route = [self routeForURL:self.htmlURL uri:@"^douban://performance/one$"];
    [[RXRRouteManager sharedInstance] _rxr_prefetchCommonUsedFilesWithinRoutes:@[route, route]];
    XCTestExpectation *finished = [self expectationWithDescription:@"Empty batch cleanup"];
    dispatch_async(dispatch_get_main_queue(), ^{ [finished fulfill]; });
    [self waitForExpectationsWithTimeout:5 handler:nil];
    XCTAssertEqual(lookups, 1u);
  } @finally {
    method_setImplementation(method, original);
    imp_removeBlock(counting);
  }
}

- (void)testPrefetchStillCancelsBatchAfterInvalidData
{
  self.validator.stopAfterInvalidData = YES;
  NSURL *invalidURL = [NSURL URLWithString:@"https://cache-performance.invalid/pages/invalid-bcef9e511f.html"];
  NSURL *pendingURL = [NSURL URLWithString:@"https://cache-performance.invalid/pages/pending-bcef9e511f.html"];
  [self finishPrefetchingURLs:@[invalidURL, pendingURL]];
  XCTAssertEqual(self.validator.stopPolicyCalls, 1u);
  XCTAssertNil([self.cache routeFileURLForRemoteURL:invalidURL]);
  XCTAssertNil([self.cache routeFileURLForRemoteURL:pendingURL]);
}

- (void)testPrefetchDoesNotTreatDiskWriteFailureAsInvalidData
{
  self.validator.stopAfterInvalidData = YES;
  NSString *blocker = [self.temporaryDirectory stringByAppendingPathComponent:@"not-a-directory"];
  XCTAssertTrue([self.html writeToFile:blocker atomically:YES]);
  self.cache.cachePath = [blocker stringByAppendingPathComponent:@"cache"];
  NSURL *secondURL = [NSURL URLWithString:@"https://cache-performance.invalid/pages/two-bcef9e511f.html"];
  [self finishPrefetchingURLs:@[self.htmlURL, secondURL]];
  XCTAssertEqual(self.validator.calls, 2u);
  XCTAssertEqual(self.validator.stopPolicyCalls, 0u);
}

- (void)finishPrefetchingURLs:(NSArray<NSURL *> *)urls
{
  RXRRouteManager *manager = [RXRRouteManager new];
  [manager.session invalidateAndCancel];
  NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
  configuration.protocolClasses = @[RXRPerformanceHTTPFixture.class];
  RXRPerformanceSessionObserver *observer = [RXRPerformanceSessionObserver new];
  observer.finished = [self expectationWithDescription:@"Prefetch complete"];
  manager.session = [NSURLSession sessionWithConfiguration:configuration delegate:observer delegateQueue:manager.sessionDelegateQueue];
  manager.dataValidator = self.validator;
  NSMutableArray<RXRRoute *> *routes = [NSMutableArray array];
  for (NSURL *url in urls) [routes addObject:[self routeForURL:url uri:@"^douban://performance/one$"]];
  [manager _rxr_prefetchCommonUsedFilesWithinRoutes:routes];
  [manager.session finishTasksAndInvalidate];
  [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testInitialViewKeepsWebViewWhileCacheLookupIsPending
{
  [self writeBundledHTML:self.html];
  [RXRRouteManager sharedInstance].routes = @[[self routeForURL:self.htmlURL uri:@"^douban://performance/one$"]];
  RXRRecordingViewController *controller = [[RXRRecordingViewController alloc] initWithURI:[NSURL URLWithString:@"douban://performance/one"]];
  XCTestExpectation *loaded = [self expectationWithDescription:@"Initial page loaded"];
  controller.didLoadRequest = ^{ [loaded fulfill]; };
  [controller loadViewIfNeeded];
  WKWebView *originalWebView = controller.webView;
  [controller viewWillAppear:NO];
  XCTAssertEqual(controller.webView, originalWebView);
  [self waitForExpectationsWithTimeout:5 handler:nil];
  XCTAssertFalse(self.validator.calledOnMain);
  XCTAssertTrue(controller.loadedRequests.firstObject.URL.isFileURL);
}

- (void)testNewReloadIgnoresStaleLookupResult
{
  [self writeBundledHTML:self.html];
  NSURL *secondURL = [NSURL URLWithString:@"https://cache-performance.invalid/pages/two-bcef9e511f.html"];
  [self.cache storeRouteFileData:self.html withRemoteURL:secondURL];
  [RXRRouteManager sharedInstance].routes = @[[self routeForURL:self.htmlURL uri:@"^douban://performance/one$"], [self routeForURL:secondURL uri:@"^douban://performance/two$"]];
  dispatch_semaphore_t releaseValidation = dispatch_semaphore_create(0);
  XCTestExpectation *started = [self expectationWithDescription:@"First validation started"];
  self.validator.beforeValidation = ^(NSURL *url) {
    [started fulfill];
    dispatch_semaphore_wait(releaseValidation, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));
  };
  RXRRecordingViewController *controller = [[RXRRecordingViewController alloc] initWithURI:[NSURL URLWithString:@"douban://performance/one"]];
  [controller loadViewIfNeeded];
  [self waitForExpectationsWithTimeout:5 handler:nil];
  XCTestExpectation *loaded = [self expectationWithDescription:@"Latest page loaded"];
  controller.didLoadRequest = ^{ [loaded fulfill]; };
  controller.uri = [NSURL URLWithString:@"douban://performance/two"];
  [controller reloadWebView];
  self.validator.beforeValidation = nil;
  dispatch_semaphore_signal(releaseValidation);
  [self waitForExpectationsWithTimeout:5 handler:nil];
  XCTAssertEqual(controller.loadedRequests.count, 1u);
  NSURLComponents *components = [NSURLComponents componentsWithURL:controller.loadedRequests.firstObject.URL resolvingAgainstBaseURL:NO];
  XCTAssertEqualObjects(components.queryItems.firstObject.value, @"douban://performance/two");
}
@end
