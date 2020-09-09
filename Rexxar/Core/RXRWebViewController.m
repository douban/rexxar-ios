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
#import "RXRCustomSchemeHandler.h"
#import "NSURL+Rexxar.h"

@interface RXRWebViewController () <WKNavigationDelegate, WKUIDelegate>

@property (nonatomic, assign) BOOL viewDidAppeared;
@property (nonatomic, weak) id<RXRWebViewDelegate> delegate;

@end

@implementation RXRWebViewController
@synthesize webView = _webView;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _shouldRegisterWebViewCustomSchemes = YES;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self setAutomaticallyAdjustsScrollViewInsets:NO];
  self.delegate = self;

  [self initWebView];
  [self.view addSubview:_webView];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  if (_webView.URL == nil) {  // means webContentProcess is terminated
    [self _rxr_cancelInterceptorsForWebView:_webView];
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
  [self _rxr_cancelInterceptorsForWebView:_webView];
  _webView.scrollView.delegate = nil;
  _webView.navigationDelegate = nil;
  _webView.UIDelegate = nil;
  [_webView stopLoading];
  _webView = nil;
}

- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];

  _webView.frame = [self webViewFrame];
}

- (void)initWebView
{
  if (!_webView) {
    _webView = [self _rxr_createWebView];
  }
}

- (void)setWebView:(WKWebView * _Nonnull)webView
{
  [self willChangeValueForKey:@"webView"];
  _webView = webView;
  [self didChangeValueForKey:@"webView"];
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

- (void)setShouldRegisterWebViewCustomSchemes:(BOOL)shouldRegisterWebViewCustomSchemes
{
  _shouldRegisterWebViewCustomSchemes = shouldRegisterWebViewCustomSchemes;
  if (_webView) {
    if (shouldRegisterWebViewCustomSchemes) {
      [self _rxr_registerWebViewCustomSchemes:_webView];
    } else {
      [self _rxr_unregisterWebViewCustomSchemes:_webView];
    }
  }
}

#pragma mark - NSURLProtocol

/**
 解决 WKWebView 不支持 URLProtocol 的问题
 http://stackoverflow.com/questions/24208229/wkwebview-and-nsurlprotocol-not-working
 */
- (void)_rxr_registerWebViewCustomSchemes:(WKWebView *)webView
{
  if ([RXRConfig useCustomScheme]) {
    return;
  }
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

- (void)_rxr_unregisterWebViewCustomSchemes:(WKWebView *)webView
{
  if ([RXRConfig useCustomScheme]) {
    return;
  }
  Class klass = [[webView valueForKey:@"browsingContextController"] class];
  SEL sel = NSSelectorFromString(@"unregisterSchemeForCustomProtocol:");
  if ([(id)klass respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [(id)klass performSelector:sel withObject:@"https"];
    [(id)klass performSelector:sel withObject:@"http"];
#pragma clang diagnostic pop
  }
}

#pragma mark - Private Methods

+ (WKProcessPool *)_rxr_sharedProcessPool
{
  static dispatch_once_t onceToken;
  static WKProcessPool *instance;

  dispatch_once(&onceToken, ^{
    instance = [[WKProcessPool alloc] init];
  });

  return instance;
}

- (WKWebView *)_rxr_createWebView
{
  WKWebViewConfiguration *webConfiguration = [[WKWebViewConfiguration alloc] init];
  webConfiguration.mediaPlaybackRequiresUserAction = NO;
  webConfiguration.allowsInlineMediaPlayback = YES;
  webConfiguration.processPool = [RXRWebViewController _rxr_sharedProcessPool];

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

  if ([RXRConfig useCustomScheme]) {
    id <WKURLSchemeHandler> handler = [RXRCustomSchemeHandler new];
    [webConfiguration setURLSchemeHandler:handler forURLScheme:@"rexxar-http"];
    [webConfiguration setURLSchemeHandler:handler forURLScheme:@"rexxar-https"];
  }

  NSString *userAgent = [RXRConfig userAgent];
  if (![WKWebView instancesRespondToSelector:@selector(setCustomUserAgent:)] && userAgent) {
    // 需要放在创建 webView 前面
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent": userAgent}];
  }

  WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:webConfiguration];
  webView.navigationDelegate = self;
  webView.UIDelegate = self;
  webView.scrollView.delegate = self;

  NSString *webviewID = [RXRWebViewStore IDForWebView:webView];
  [RXRWebViewStore setWebView:webView withWebViewID:webviewID];

  if ([webView respondsToSelector:@selector(setCustomUserAgent:)] && userAgent) {
    userAgent = [userAgent stringByAppendingFormat:@" webviewID/%@", webviewID];
    [webView setCustomUserAgent:userAgent];
  }

  if (self.shouldRegisterWebViewCustomSchemes) {
    [self _rxr_registerWebViewCustomSchemes:webView];
  } else {
    [self _rxr_unregisterWebViewCustomSchemes:webView];
  }

  return webView;
}

// 由于所有的 WebView 共享一个 ProcessPool, 为了避免 WebView 释放掉后请求没有释放的情况，这里手动释放掉还未完成的请求。
- (void)_rxr_cancelInterceptorsForWebView:(WKWebView *)webView
{
  NSString *webViewID = [RXRWebViewStore IDForWebView:webView];
  NSArray<NSURLProtocol *> *urlProtocols = [RXRWebViewStore interceptorsForWebViewID:webViewID];

  for (NSURLProtocol *urlProtocol in urlProtocols) {
    [urlProtocol stopLoading];
    [RXRWebViewStore removeInterceptor:urlProtocol withWebViewID:webViewID];
  }
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
    NSMutableURLRequest *request = [navigationAction.request mutableCopy];
    if ([request.URL rxr_isRexxarHttpScheme]) {
      request.URL = [request.URL rxr_urlByReplacingRexxarSchemeWithHttp];
    }
    allowed = [self.delegate webView:webView
          shouldStartLoadWithRequest:request
                      navigationType:navigationAction.navigationType];

    // `WKWebView` 无法打开非 HTTP 链接，检查是否需要使用 `UIApplication.openURL` 来处理请求的 URL。
    NSURL *url = request.URL;
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

  if (self.navigationController.topViewController == self && !self.navigationController.presentedViewController) {
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

  if (self.navigationController.topViewController == self && !self.navigationController.presentedViewController) {
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

  if (self.navigationController.topViewController == self && !self.navigationController.presentedViewController) {
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
    [RXRConfig rxr_logWithType:RXRLogTypeWebViewLoadingError error:error requestURL:webView.URL localFilePath:nil userInfo:nil];
  }

  // Handle Error
  if ([RXRConfig rxr_canHandleError]) {
    [RXRConfig rxr_handleError:error fromReporter:self];
  }

  [self _rxr_resetControllerAppearance];
}

@end

#pragma mark - RXRWebViewStore

static NSLock *sStoreLock()
{
  static NSLock *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[NSLock alloc] init];
  });
  return instance;
}

static NSMapTable *sWebviewsTable()
{
  static NSMapTable *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [NSMapTable mapTableWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableWeakMemory];
  });
  return instance;
}

@implementation RXRWebViewStore

+ (NSString *)IDForWebView:(WKWebView *)webView
{
  return [NSString stringWithFormat:@"%p", webView];
}

+ (WKWebView *)webViewForID:(NSString *)webViewID;
{
  [sStoreLock() lock];
  WKWebView *webview = [sWebviewsTable() objectForKey:webViewID];
  [sStoreLock() unlock];
  return webview;
}

+ (void)setWebView:(WKWebView *)webView withWebViewID:(NSString *)webViewID;
{
  [sStoreLock() lock];
  [sWebviewsTable() setObject:webView forKey:webViewID];
  [sStoreLock() unlock];
}

static NSMapTable *sWebViewInterceptorTable()
{
  static NSMapTable *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [NSMapTable mapTableWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableWeakMemory];
  });
  return instance;
}

+ (void)addInterceptor:(NSURLProtocol *)interceptor withWebViewID:(NSString *)webViewID
{
  [sStoreLock() lock];
  NSString *key = [NSString stringWithFormat:@"%@:%p", webViewID, interceptor];
  [sWebViewInterceptorTable() setObject:interceptor forKey:key];
  [sStoreLock() unlock];
}

+ (void)removeInterceptor:(NSURLProtocol *)interceptor withWebViewID:(NSString *)webViewID
{
  [sStoreLock() lock];
  NSString *key = [NSString stringWithFormat:@"%@:%p", webViewID, interceptor];
  [sWebViewInterceptorTable() setObject:nil forKey:key];
  [sStoreLock() unlock];
}

+ (NSArray<NSURLProtocol *> *)interceptorsForWebViewID:(NSString *)webViewID
{
  [sStoreLock() lock];
  NSMutableArray<NSURLProtocol *> *instances = [NSMutableArray array];
  NSEnumerator *keyEnumerator = [sWebViewInterceptorTable() keyEnumerator];
  for (NSString *key in [keyEnumerator allObjects]) {
    if ([key hasPrefix:webViewID]) {
      NSURLProtocol *instance = [sWebViewInterceptorTable() objectForKey:key];
      if (instance != nil) {
        [instances addObject:instance];
      }
    }
  }
  [sStoreLock() unlock];
  return instances;
}

@end
