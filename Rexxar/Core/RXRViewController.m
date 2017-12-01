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
#import "RXRWidget.h"

#import "UIColor+Rexxar.h"
#import "NSURL+Rexxar.h"


@interface RXRViewController ()

@property (nonatomic, copy) NSURL *htmlFileURL;
@property (nonatomic, copy) NSURL *requestURL;

@end


@implementation RXRViewController

#pragma mark - LifeCycle

- (instancetype)initWithURI:(NSURL *)uri htmlFileURL:(NSURL *)htmlFileURL
{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _uri = [uri copy];
    _htmlFileURL = [htmlFileURL copy];
  }
  return self;
}

- (instancetype)initWithURI:(NSURL *)uri
{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _uri = [uri copy];
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  [self reloadWebView];
  [RXRCacheFileInterceptor registerInterceptor];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  if (!self.webView.URL || [self.webView.URL isEqual:[NSURL URLWithString:@"about:blank"]]) {
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
  [RXRCacheFileInterceptor unregisterInterceptor];
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

#pragma mark - Private Methods

- (NSURL *)_rxr_htmlURLWithUri:(NSURL *)uri htmlFileURL:(NSURL *)htmlFileURL
{
  if (!htmlFileURL) {
    // 没有设置 htmlFileURL，则使用本地 html 文件或者服务器读取 html 文件。

    htmlFileURL = [[RXRRouteManager sharedInstance] remoteHtmlURLForURI:self.uri];

    if (!htmlFileURL && RXRConfig.logger && [RXRConfig.logger respondsToSelector:@selector(rexxarDidLogWithLogObject:)]) {
      NSDictionary *otherInfo;
      if (RXRRouteManager.sharedInstance.routesDeployTime) {
        otherInfo = @{logOtherInfoRoutesDepolyTimeKey: RXRRouteManager.sharedInstance.routesDeployTime};
      }
      RXRLogObject *logObj = [[RXRLogObject alloc] initWithLogType:RXRLogTypeNoRemoteHTMLForURI
                                                             error:nil
                                                        requestURL:self.uri
                                                     localFilePath:nil
                                                  otherInformation:otherInfo];
      [RXRConfig.logger rexxarDidLogWithLogObject:logObj];
    }

    if ([RXRConfig isCacheEnable]) {
      // 如果缓存启用，尝试读取本地文件。如果没有本地文件（本地文件包括缓存，和资源文件夹），则从服务器读取。
      NSURL *localHtmlURL = [[RXRRouteManager sharedInstance] localHtmlURLForURI:self.uri];
      if (localHtmlURL) {
        htmlFileURL = localHtmlURL;
      }
      else if (!localHtmlURL && RXRConfig.logger && [RXRConfig.logger respondsToSelector:@selector(rexxarDidLogWithLogObject:)]) {
        NSDictionary *otherInfo;
        if (RXRRouteManager.sharedInstance.routesDeployTime) {
          otherInfo = @{logOtherInfoRoutesDepolyTimeKey: RXRRouteManager.sharedInstance.routesDeployTime};
        }
        RXRLogObject *logObj = [[RXRLogObject alloc] initWithLogType:RXRLogTypeNoLocalHTMLForURI
                                                               error:nil
                                                          requestURL:self.uri
                                                       localFilePath:nil
                                                    otherInformation:otherInfo];
        [RXRConfig.logger rexxarDidLogWithLogObject:logObj];
      }
    }
  }

  if (htmlFileURL.query.length != 0 && htmlFileURL.fragment.length != 0) {
    // 为了方便 escape 正确的 uri，做了下面的假设。之后放弃 iOS 7 后可以改用 `queryItem` 来实现。
    // 做个合理假设：html URL 中不应该有 query string 和 fragment。
    RXRWarnLog(@"local html 's format is not right! Url has query and fragment.");
  }

  // `absoluteString` 返回的是已经 escape 过的文本，这里先转换为原始文本。
  NSString *uriText = uri.absoluteString.stringByRemovingPercentEncoding;
  // 把 uri 的原始文本所有内容全部 escape。
  NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@""];
  uriText = [uriText stringByAddingPercentEncodingWithAllowedCharacters:set];

  return  [NSURL URLWithString:[NSString stringWithFormat:@"%@?uri=%@", htmlFileURL.absoluteString, uriText]];
}

- (BOOL)_rxr_openWebPage:(NSURL *)url
{
  // 让 App 打开网页，通常 `UIApplicationDelegate` 都会实现 open url 相关的 delegate 方法。
  id<UIApplicationDelegate> delegate = [[UIApplication sharedApplication] delegate];
  if ([delegate respondsToSelector:@selector(application:openURL:options:)]) {
    [delegate application:[UIApplication sharedApplication]
                  openURL:url
                  options:@{}];
  } else if ([delegate respondsToSelector:@selector(application:openURL:sourceApplication:annotation:)]) {
    [delegate application:[UIApplication sharedApplication]
                  openURL:url
        sourceApplication:NSStringFromClass([self class])
               annotation:@""];
  } else if ([delegate respondsToSelector:@selector(application:handleOpenURL:)]) {
    [delegate application:[UIApplication sharedApplication] handleOpenURL:url];
  }

  return YES;
}

- (void)_rxr_onPageDestroy
{
  [self callJavaScript:@"window.Rexxar.Lifecycle.onPageDestroy()" jsonParameter:nil];
}

@end
