//
//  RXRViewController.m
//  Rexxar
//
//  Created by Tony Li on 11/4/15.
//  Copyright © 2015 Douban Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RXRViewController.h"
#import "RXRCacheFileIntercepter.h"
#import "RXRRouteManager.h"
#import "RXRLogging.h"
#import "RXRConfig.h"
#import "RXRWidget.h"

#import "UIColor+Rexxar.h"
#import "NSURL+Rexxar.h"


@interface RXRViewController ()

@property (nonatomic, strong) NSURL *requestURL;

@property (nonatomic, strong) NSURL *htmlFileURL;

@end


@implementation RXRViewController

#pragma mark - LifeCycle

- (instancetype)initWithURI:(NSURL *)uri htmlFileURL:(NSURL *)htmlFileURL
{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _uri = uri;
    _htmlFileURL = htmlFileURL;
  }
  return self;
}



- (instancetype)initWithURI:(NSURL *)uri
{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _uri = uri;
  }
  return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  NSAssert(NO, @"Should use initWithURI: instead.");
  return nil;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
  _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
  _webView.dataDetectorTypes = UIDataDetectorTypeLink;
  _webView.scalesPageToFit = YES;
  _webView.delegate = self;
  [self.view addSubview:_webView];

  [self reloadWebView];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [NSURLProtocol registerClass:RXRCacheFileIntercepter.class];
  [self onPageVisible];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  [NSURLProtocol unregisterClass:RXRCacheFileIntercepter.class];
  [self onPageInvisible];
}

#pragma mark - Public methods

- (void)reloadWebView
{
  if (!self.requestURL) {
    _requestURL = [self _rxr_htmlURLWithUri:self.uri htmlFileURL:self.htmlFileURL];
  }

  if (self.requestURL) {
    [_webView loadRequest:[NSURLRequest requestWithURL:self.requestURL]];
  }
}

- (void)onPageVisible
{
  // Call the WebView's visiblity change hook for javascript.
  RXRDebugLog(@"window.Rexxar.Lifecycle.onPageVisible: %@",
              [_webView stringByEvaluatingJavaScriptFromString:@"window.Rexxar.Lifecycle.onPageVisible()"]);
}

- (void)onPageInvisible
{
  // Call the WebView's visiblity change hook for javascript.
  RXRDebugLog(@"window.Rexxar.Lifecycle.onPageInvisible: %@",
              [_webView stringByEvaluatingJavaScriptFromString:@"window.Rexxar.Lifecycle.onPageInvisible()"]);
}

#pragma mark - UIWebViewDelegate's method

- (BOOL)webView:(UIWebView *)webView
    shouldStartLoadWithRequest:(NSURLRequest *)request
    navigationType:(UIWebViewNavigationType)navigationType
{
  NSURL *reqURL = request.URL;

  if ([reqURL isEqual:self.requestURL]) {
    return YES;
  }

  // http:// or https:// 开头，则打开网页
  if ([reqURL rxr_isHttpOrHttps]) {
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

  return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
  [self _rxr_resetControllerAppearance];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
  [self _rxr_resetControllerAppearance];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
  [self _rxr_resetControllerAppearance];
}

#pragma mark - Private Methods

- (NSURL *)_rxr_htmlURLWithUri:(NSURL *)uri htmlFileURL:(NSURL *)htmlFileURL
{
  if (!htmlFileURL) {
    // 没有设置 htmlFileURL，则使用本地 html 文件或者服务器读取 html 文件。

    htmlFileURL = [[RXRRouteManager sharedInstance] remoteHtmlURLForURI:self.uri];

    if ([RXRConfig isCacheEnable]) {
     // 如果缓存启用，尝试读取本地文件。如果没有本地文件（本地文件包括缓存，和资源文件夹），则从服务器读取。
      NSURL *localHtmlURL = [[RXRRouteManager sharedInstance] localHtmlURLForURI:self.uri];
      if (localHtmlURL) {
        htmlFileURL = localHtmlURL;
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

- (void)_rxr_resetControllerAppearance
{
  self.title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];

  NSString *bgColor = [self.webView stringByEvaluatingJavaScriptFromString:
                       @"window.getComputedStyle(document.getElementsByTagName('body')[0]).backgroundColor"];
  self.webView.backgroundColor = [UIColor rxr_colorWithComponent:bgColor] ?: [UIColor whiteColor];
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
        sourceApplication:nil
               annotation:@""];
  } else if ([delegate respondsToSelector:@selector(application:handleOpenURL:)]) {
    [delegate application:[UIApplication sharedApplication] handleOpenURL:url];
  }

  return YES;
}

@end
