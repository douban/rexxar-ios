//
//  RXRWebViewController.m
//  Rexxar
//
//  Created by XueMing on 15/05/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

#import "RXRWebViewController.h"
#import "UIColor+Rexxar.h"
#import "RXRLogger.h"
#import "RXRConfig.h"
#import "RXRRouteManager.h"
#import "RXRConfig+Rexxar.h"
#import "RXRErrorHandler.h"

static WKProcessPool *sProcessPool;

@interface RXRWebViewController () <WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate>

@property (nonatomic, assign) BOOL viewDidAppeared;
@property (nonatomic, weak) id<RXRWebViewDelegate> delegate;

@end

@implementation RXRWebViewController
@synthesize webView = _webView;

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self setAutomaticallyAdjustsScrollViewInsets:NO];
  self.delegate = self;

  _webView = [self _rxr_createWebView];
  [self.view addSubview:_webView];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  if (_webView.URL == nil) {  // means webContentProcess is terminated
    [_webView removeFromSuperview];
    _webView = [self _rxr_createWebView];
    [self.view addSubview:_webView];
    [self.view setNeedsLayout];
  }
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self setViewDidAppeared:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [self setViewDidAppeared:NO];
}

- (void)dealloc
{
  _webView.scrollView.delegate = nil;
  _webView.navigationDelegate = nil;
  _webView.UIDelegate = nil;
  [_webView stopLoading];
  _webView = nil;
  sProcessPool = [[WKProcessPool alloc] init];
}

- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];

  _webView.frame = [self webViewFrame];
}

- (CGRect)webViewFrame
{
  CGRect frame = CGRectZero;
  frame.origin.x = 0;
  frame.origin.y = self.topLayoutGuide.length;
  frame.size.width = CGRectGetWidth(self.view.bounds);
  frame.size.height = CGRectGetHeight(self.view.bounds) - self.topLayoutGuide.length;
  return frame;
}

- (void)loadRequest:(NSURLRequest *)request
{
  if ([request.URL isFileURL]) {
    if ([_webView respondsToSelector:@selector(loadFileURL:allowingReadAccessToURL:)]) {
      NSURLComponents *comp = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:YES];
      comp.query = nil;
      NSURL *allowingURL = [comp.URL URLByDeletingLastPathComponent];
      [_webView loadFileURL:request.URL allowingReadAccessToURL:allowingURL];
    } else {
      NSFileManager *m = [NSFileManager defaultManager];
      NSURL *sourceURL = [NSURL fileURLWithPath:request.URL.path];
      NSURL *tmpURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"rexxar"];
      NSURL *destURL = [tmpURL URLByAppendingPathComponent:sourceURL.lastPathComponent];

      [m createDirectoryAtURL:tmpURL withIntermediateDirectories:YES attributes:nil error:nil];
      [m removeItemAtURL:destURL error:nil];
      [m copyItemAtURL:sourceURL toURL:destURL error:nil];

      NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", destURL, request.URL.query]];
      [_webView loadRequest:[NSURLRequest requestWithURL:URL]];
    }
  } else {
    [_webView loadRequest:request];
  }
}

#pragma mark - NSURLProtocol

/**
 解决 WKWebView 不支持 URLProtocol 的问题
 http://stackoverflow.com/questions/24208229/wkwebview-and-nsurlprotocol-not-working
 */
- (void)_rxr_registerWebViewCustomSchemes:(WKWebView *)webView
{
  Class klass = [[webView valueForKey:@"browsingContextController"] class];
  SEL sel = NSSelectorFromString(@"registerSchemeForCustomProtocol:");
  if ([(id)klass respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [(id)klass performSelector:sel withObject:@"https"];
    [(id)klass performSelector:sel withObject:@"http"];
#pragma clang diagnostic pop
  }
}

#pragma mark - Private Methods

- (WKProcessPool *)_rxr_sharedProcessPool
{
  if (!sProcessPool) {
    sProcessPool = [[WKProcessPool alloc] init];
  }
  return sProcessPool;
}

- (WKWebView *)_rxr_createWebView
{
  WKWebViewConfiguration *webConfiguration = [[WKWebViewConfiguration alloc] init];
  webConfiguration.mediaPlaybackRequiresUserAction = NO;
  webConfiguration.allowsInlineMediaPlayback = YES;
  webConfiguration.processPool = [self _rxr_sharedProcessPool];

  // iOS9
  if ([webConfiguration respondsToSelector:@selector(websiteDataStore)]) {
    webConfiguration.requiresUserActionForMediaPlayback = NO;
    webConfiguration.websiteDataStore = [WKWebsiteDataStore defaultDataStore];
  }

  // iOS10
  if ([webConfiguration respondsToSelector:@selector(dataDetectorTypes)]) {
    webConfiguration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    webConfiguration.dataDetectorTypes = WKDataDetectorTypeLink | WKDataDetectorTypePhoneNumber;
  }

  WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:webConfiguration];
  webView.navigationDelegate = self;
  webView.UIDelegate = self;
  webView.scrollView.delegate = self;

  [self _rxr_registerWebViewCustomSchemes:webView];

  return webView;
}

- (void)_rxr_resetControllerAppearance
{
  __weak typeof(self) weakSelf = self;

  [_webView evaluateJavaScript:@"document.title"
             completionHandler:^(NSString *title, NSError *error) {
               if ([title length] > 0 && error == nil) {
                 weakSelf.title = title;
               }
             }];

  [_webView evaluateJavaScript:@"window.getComputedStyle(document.getElementsByTagName('body')[0]).backgroundColor"
             completionHandler:^(NSString *bgColor, NSError *error) {
               if ([bgColor length] > 0 && error == nil) {
                 weakSelf.webView.backgroundColor = [UIColor rxr_colorWithComponent:bgColor];
               }
             }];
}

- (NSString *)_rxr_titleForURL:(NSURL *)URL
{
  if ([URL.host hasSuffix:@".douban.com"]) {
    return @"豆瓣";
  }

  if ([URL.scheme hasPrefix:@"http"]) {
    return URL.host;
  }

  return [URL.pathComponents lastObject];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
  BOOL allowed = YES;
  if ([self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
    allowed = [self.delegate webView:webView
          shouldStartLoadWithRequest:navigationAction.request
                      navigationType:navigationAction.navigationType];

    // `WKWebView` 无法打开非 HTTP 链接，检查是否需要使用 `UIApplication.openURL` 来处理请求的 URL。
    NSURL *url = navigationAction.request.URL;
    if (allowed && ![url isFileURL]) {
      BOOL isHTTP = [url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"];
      BOOL useOpenURL = (isHTTP && [url.host isEqualToString:@"itunes.apple.com"]) // iTunes 链接。
      || (!isHTTP && [[UIApplication sharedApplication] canOpenURL:url]); // 可以处理的非 HTTP 链接。
      if (useOpenURL) {
        [[UIApplication sharedApplication] openURL:url];
        allowed = NO;
      }
    }
  }
  decisionHandler(allowed ? WKNavigationActionPolicyAllow : WKNavigationActionPolicyCancel);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
  if ([self.delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
    [self.delegate webViewDidStartLoad:webView];
  }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
  if ([self.delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
    [self.delegate webViewDidFinishLoad:webView];
  }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
  if ([self.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
    [self.delegate webView:webView didFailLoadWithError:error];
  }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
  if ([self.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
    [self.delegate webView:webView didFailLoadWithError:error];
  }
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView
{
  if ([self.delegate respondsToSelector:@selector(webViewDidTerminate:)]) {
    [self.delegate webViewDidTerminate:webView];
  }
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
  // 如果页面 push 或者 present 动画还没有完成，弹窗出不来，导致 completionHandler 不能执行
  if (!_viewDidAppeared) {
    completionHandler();
    return;
  }

  NSString *title = [self _rxr_titleForURL:frame.request.URL];
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    completionHandler();
  }];
  [alert addAction:action];

  if (self.navigationController.topViewController == self) {
    [self presentViewController:alert animated:YES completion:nil];
  } else {
    completionHandler();
  }
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler
{
  if (!_viewDidAppeared) {
    completionHandler(NO);
    return;
  }

  NSString *title = [self _rxr_titleForURL:frame.request.URL];
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    completionHandler(NO);
  }];
  UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    completionHandler(YES);
  }];
  [alert addAction:cancelAction];
  [alert addAction:confirmAction];

  if (self.navigationController.topViewController == self) {
    [self presentViewController:alert animated:YES completion:nil];
  } else {
    completionHandler(NO);
  }
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler
{
  NSString *title = [self _rxr_titleForURL:frame.request.URL];
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:prompt preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    completionHandler(nil);
  }];
  UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    if (alert.textFields.count > 0) {
      completionHandler([alert.textFields[0] text]);
    } else {
      completionHandler(nil);
    }
  }];
  [alert addTextFieldWithConfigurationHandler:nil];
  [alert addAction:cancelAction];
  [alert addAction:confirmAction];

  if (self.navigationController.topViewController == self) {
    [self presentViewController:alert animated:YES completion:nil];
  } else {
    completionHandler(nil);
  }
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
  // Open page in current web view for 'Open in New Window' links.
  if (navigationAction.targetFrame == nil) {
    [webView loadRequest:navigationAction.request];
  }
  return nil;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
  scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
}

#pragma mark - DOUWebViewDelegate

- (BOOL)webView:(WKWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(WKNavigationType)navigationType
{
  return YES;
}

- (void)webViewDidStartLoad:(WKWebView *)webView
{
  [self _rxr_resetControllerAppearance];
}

- (void)webViewDidFinishLoad:(WKWebView *)webView
{
  [self _rxr_resetControllerAppearance];
}

- (void)webView:(WKWebView *)webView didFailLoadWithError:(NSError *)error
{
  // Log
  if ([RXRConfig rxr_canLog]) {
    NSDictionary *otherInfo;
    if (RXRRouteManager.sharedInstance.routesDeployTime) {
      otherInfo = @{logOtherInfoRoutesDepolyTimeKey: RXRRouteManager.sharedInstance.routesDeployTime};
    }
    RXRLogObject *logObj = [[RXRLogObject alloc] initWithLogType:RXRLogTypeWebViewLoadingError
                                                           error:error
                                                      requestURL:webView.URL
                                                   localFilePath:nil
                                                otherInformation:otherInfo];
    [RXRConfig rxr_logWithLogObject:logObj];
  }

  // Handle Error
  if ([RXRConfig rxr_canHandleError]) {
    [RXRConfig rxr_handleError:error fromReporter:self];
  }

  [self _rxr_resetControllerAppearance];
}

@end
