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

@end

@interface RXRWebViewController : UIViewController <RXRWebViewDelegate>

@property (nonatomic, readonly) WKWebView *webView;

- (void)loadRequest:(NSURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
