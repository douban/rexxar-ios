//
//  RXRWebViewController.h
//  Rexxar
//
//  Created by XueMing on 15/05/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RXRWebViewDelegate <NSObject>

@optional
- (BOOL)webView:(WKWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(WKNavigationType)navigationType;
- (void)webViewDidStartLoad:(WKWebView *)webView;
- (void)webViewDidFinishLoad:(WKWebView *)webView;
- (void)webView:(WKWebView *)webView didFailLoadWithError:(nullable NSError *)error;
- (void)webViewDidTerminate:(WKWebView *)webView;
@end

@interface RXRWebViewController : UIViewController <RXRWebViewDelegate, UIScrollViewDelegate>

@property (nonatomic, readonly) WKWebView *webView;
@property (nonatomic, assign) BOOL shouldRegisterWebViewCustomSchemes; // default is YES;

- (void)loadRequest:(NSURLRequest *)request;
- (CGRect)webViewFrame;
- (void)initWebView;

@end

@interface RXRWebViewStore: NSObject

+ (NSString *)IDForWebView:(WKWebView *)webView;
+ (void)setWebView:(WKWebView *)webView withWebViewID:(NSString *)webViewID;
+ (WKWebView *)webViewForID:(NSString *)webViewID;

+ (void)addInterceptor:(NSURLProtocol *)interceptor withWebViewID:(NSString *)webViewID;
+ (void)removeInterceptor:(NSURLProtocol *)interceptor withWebViewID:(NSString *)webViewID;
+ (NSArray<NSURLProtocol *> *)interceptorsForWebViewID:(NSString *)webViewID;

@end

NS_ASSUME_NONNULL_END
