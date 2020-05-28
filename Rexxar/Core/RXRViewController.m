//
//  RXRViewController.m
//  Rexxar
//
//  Created by Tony Li on 11/4/15.
//  Copyright © 2015 Douban Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RXRViewController.h"
#import "RXRCacheFileInterceptor.h"
#import "RXRRouteManager.h"
#import "RXRLogger.h"
#import "RXRConfig.h"
#import "RXRConfig+Rexxar.h"
#import "RXRWidget.h"
#import "UIColor+Rexxar.h"
#import "NSURL+Rexxar.h"
#import "RXRErrorHandler.h"

@interface RXRViewController ()

@property (nonatomic, copy) NSURL *htmlFileURL;
@property (nonatomic, copy) NSURL *requestURL;

@property (nonatomic, strong) NSMutableDictionary *reloadRecord;
@property (nonatomic, assign) BOOL isWebViewOnceLoaded;

@end


@implementation RXRViewController

#pragma mark - LifeCycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  NSAssert(NO, @"Use initWithURI:htmlFileURL:");

  return [self initWithURI:[NSURL URLWithString:@"http"] htmlFileURL:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  NSAssert(NO, @"Use initWithURI:htmlFileURL:");

  return [self initWithURI:[NSURL URLWithString:@"http"] htmlFileURL:nil];
}

- (instancetype)initWithURI:(NSURL *)uri htmlFileURL:(NSURL *)htmlFileURL
{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _uri = [uri copy];
    _htmlFileURL = [htmlFileURL copy];
    _reloadRecord = [NSMutableDictionary dictionary];

    [RXRCacheFileInterceptor registerRXRProtocolClass:[RXRCacheFileInterceptor class]];
  }
  return self;
}

- (instancetype)initWithURI:(NSURL *)uri
{
  return [self initWithURI:uri htmlFileURL:nil];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self reloadWebView];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  if (self.isWebViewOnceLoaded && (!self.webView.URL || [self.webView.URL isEqual:[NSURL URLWithString:@"about:blank"]])) {
    [self reloadWebView];
  }

  [self onPageVisible];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  [self onPageInvisible];
}

- (void)dealloc
{
  [RXRCacheFileInterceptor unregisterRXRProtocolClass:[RXRCacheFileInterceptor class]];
  [self _rxr_onPageDestroy];
}

#pragma mark - Public methods

- (void)reloadWebView
{
  if (!_requestURL) {
    _requestURL = [self _rxr_htmlURLWithUri:self.uri htmlFileURL:self.htmlFileURL];
  }

  if (_requestURL) {
    [self loadRequest:[NSURLRequest requestWithURL:_requestURL]];
  }
}

#pragma mark - Native Call WebView JavaScript interfaces.

- (void)onPageVisible
{
  // Call the WebView's visiblity change hook for javascript.
  [self callJavaScript:@"window.Rexxar.Lifecycle.onPageVisible" jsonParameter:nil];
}

- (void)onPageInvisible
{
  // Call the WebView's visiblity change hook for javascript.
  [self callJavaScript:@"window.Rexxar.Lifecycle.onPageInvisible" jsonParameter:nil];
}

- (void)callJavaScript:(NSString *)function jsonParameter:(NSString *)jsonParameter
{
  NSString *jsCall;
  if (jsonParameter) {
    jsonParameter = [jsonParameter stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    jsonParameter = [jsonParameter stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    jsonParameter = [jsonParameter stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    jsonParameter = [jsonParameter stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    jsonParameter = [jsonParameter stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    jsonParameter = [jsonParameter stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    jsonParameter = [jsonParameter stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    jsonParameter = [jsonParameter stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    jsCall = [NSString stringWithFormat:@"%@('%@')", function, jsonParameter];
  } else {
    jsCall = [NSString stringWithFormat:@"%@()", function];
  }

  [self.webView evaluateJavaScript:jsCall completionHandler:nil];

  RXRDebugLog(@"jsCall: function:%@, parameter %@", function, jsonParameter);
}

#pragma mark - RXRWebViewDelegate

- (BOOL)webView:(WKWebView *)webView
    shouldStartLoadWithRequest:(NSURLRequest *)request
    navigationType:(WKNavigationType)navigationType
{
  NSURL *reqURL = request.URL;

  if ([reqURL isEqual:_requestURL]) {
    return YES;
  }

  // http:// or https:// 开头，则打开网页
  if ([reqURL rxr_isHttpOrHttps] && navigationType == WKNavigationTypeLinkActivated) {
    return ![self _rxr_openWebPage:reqURL];
  }

  NSString *scheme = [RXRConfig rxrProtocolScheme];
  NSString *host = [RXRConfig rxrProtocolHost];

  if ([request.URL.scheme isEqualToString:scheme]
      && [request.URL.host isEqualToString:host] ) {

    NSURL *URL = request.URL;

    for (id<RXRWidget> widget in self.widgets) {
      if ([widget canPerformWithURL:URL]) {
        [widget prepareWithURL:URL];
        [widget performWithController:self];
        RXRDebugLog(@"Rexxar callback handle: %@", URL);
        return NO;
      }
    }

    RXRDebugLog(@"Rexxar callback can not handle: %@", URL);
  }

  return [super webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
}

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
  if (![navigationResponse.response isKindOfClass:[NSHTTPURLResponse class]]) {
    decisionHandler(WKNavigationResponsePolicyAllow);
    return;
  }

  // Log when not 200 and not 404
  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)navigationResponse.response;
  if (httpResponse.statusCode != 200
      && httpResponse.statusCode != 404
      && [RXRConfig rxr_canLog]) {
    RXRLogObject *logObj = [[RXRLogObject alloc] initWithLogType:RXRLogTypeWebViewLoadNot200
                                                           error:nil
                                                      requestURL:httpResponse.URL
                                                   localFilePath:nil
                                                otherInformation:@{logOtherInfoStatusCodeKey: @(httpResponse.statusCode)}];
    [RXRConfig rxr_logWithLogObject:logObj];
  }

  // Deal with 404
  if (!httpResponse.URL.absoluteString) {
    decisionHandler(WKNavigationResponsePolicyAllow);
    return;
  }
  NSInteger reloadCount = [_reloadRecord[httpResponse.URL.absoluteString] integerValue];

  if (httpResponse.statusCode == 404 && reloadCount < RXRConfig.reloadLimitWhen404) {
    decisionHandler(WKNavigationResponsePolicyCancel);

    _reloadRecord[httpResponse.URL.absoluteString] = @(++reloadCount);
    [[RXRRouteManager sharedInstance] updateRoutesWithCompletion:^(BOOL success) {
      if (success) {
        self.requestURL = nil;
        [self reloadWebView];
      }
    }];

    return;
  }
  else if (httpResponse.statusCode == 404) {
    decisionHandler(WKNavigationResponsePolicyCancel);
    // Log 404 error when reload not work
    [RXRConfig rxr_logWithType:RXRLogTypeWebViewLoad404 error:nil requestURL:httpResponse.URL localFilePath:nil userInfo:nil];

    if ([RXRConfig rxr_canHandleError]) {
      NSDictionary *userInfo = httpResponse.URL ? @{rxrErrorUserInfoURLKey: httpResponse.URL} : nil;
      NSError *error = [NSError errorWithDomain:rxrHttpErrorDomain code:rxrHttpResponseErrorNotFound userInfo:userInfo];
      [RXRConfig rxr_handleError:error fromReporter:self];
    }

    return;
  }

  decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webViewDidFinishLoad:(WKWebView *)webView
{
  [super webViewDidFinishLoad:webView];
  self.isWebViewOnceLoaded = YES;
}

- (void)webViewDidTerminate:(WKWebView *)webView
{
  [self reloadWebView];
}

#pragma mark - Private Methods

- (NSURL *)_rxr_htmlURLWithUri:(NSURL *)uri htmlFileURL:(NSURL *)htmlFileURL
{
  if (!htmlFileURL) {
    // 没有设置 htmlFileURL，则使用本地 html 文件或者服务器读取 html 文件。

    htmlFileURL = [[RXRRouteManager sharedInstance] remoteHtmlURLForURI:self.uri];

    if (!htmlFileURL && [RXRConfig rxr_canLog]) {
      [RXRConfig rxr_logWithType:RXRLogTypeNoRemoteHTMLForURI error:nil requestURL:self.uri localFilePath:nil userInfo:nil];
    }

    if ([RXRConfig isCacheEnable]) {
      // 如果缓存启用，尝试读取本地文件。如果没有本地文件（本地文件包括缓存，和资源文件夹），则从服务器读取。
      NSURL *localHtmlURL = [[RXRRouteManager sharedInstance] localHtmlURLForURI:self.uri];
      if (localHtmlURL) {
        htmlFileURL = localHtmlURL;
      }
      else if (!localHtmlURL && [RXRConfig rxr_canLog]) {
        [RXRConfig rxr_logWithType:RXRLogTypeNoLocalHTMLForURI error:nil requestURL:self.uri localFilePath:nil userInfo:nil];
      }
    }
  }

  if (!htmlFileURL) {
    NSAssert(NO, @"Should not be here");
    return nil;
  }

  // add uri query
  NSURLComponents *comp = [NSURLComponents componentsWithURL:htmlFileURL resolvingAgainstBaseURL:YES];
  if (!comp) {
    NSAssert(NO, @"Should not be here");
    return nil;
  }

  NSURLQueryItem *uriItem = [NSURLQueryItem queryItemWithName:@"uri" value:uri.absoluteString];
  NSMutableArray *queryItems = [comp.queryItems mutableCopy];
  if (queryItems.count && uriItem) {
    [queryItems addObject:uriItem];
    comp.queryItems = queryItems;
  }
  else if (uriItem) {
    comp.queryItems = @[uriItem];
  }

  return [comp.URL rxr_urlByReplacingHttpWithRexxarScheme];
}

- (BOOL)_rxr_openWebPage:(NSURL *)url
{
  // 让 App 打开网页，通常 `UIApplicationDelegate` 都会实现 open url 相关的 delegate 方法。
  id<UIApplicationDelegate> delegate = [[UIApplication sharedApplication] delegate];
  BOOL isIOS9Above = NO;
  if (@available(iOS 9.0, *)) {
    isIOS9Above = YES;
  }
  if (isIOS9Above && [delegate respondsToSelector:@selector(application:openURL:options:)]) {
    [delegate application:[UIApplication sharedApplication]
                  openURL:url
                  options:@{}];
  } else if ([delegate respondsToSelector:@selector(application:openURL:sourceApplication:annotation:)]) {
    [delegate application:[UIApplication sharedApplication]
                  openURL:url
        sourceApplication:nil
               annotation:@""];
  } else if ([delegate respondsToSelector:@selector(application:handleOpenURL:)]) {
    [delegate application:[UIApplication sharedApplication] handleOpenURL:url];
  }

  return YES;
}

- (void)_rxr_onPageDestroy
{
  [self callJavaScript:@"window.Rexxar.Lifecycle.onPageDestroy" jsonParameter:nil];
}

@end
