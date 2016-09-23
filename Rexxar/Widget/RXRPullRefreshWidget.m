//
//  RXRPullRefreshWidget.m
//  Rexxar
//
//  Created by GUO Lin on 8/5/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

@import UIKit;

#import "RXRPullRefreshWidget.h"
#import "RXRViewController.h"
#import "NSURL+Rexxar.h"
#import "NSDictionary+RXRMultipleItems.h"

@interface RXRPullRefreshWidget ()

@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, copy) NSString *action;
@property (nonatomic, assign) BOOL onRefreshStart;

@end


@implementation RXRPullRefreshWidget

- (BOOL)canPerformWithURL:(NSURL *)URL
{
  NSString *path = URL.path;
  if (path && [path isEqualToString:@"/widget/pull_to_refresh"]) {
    return YES;
  }
  return NO;
}

- (void)prepareWithURL:(NSURL *)URL
{
  NSDictionary *queryItems = [URL rxr_queryDictionary];
  self.action = [queryItems rxr_itemForKey:@"action"];
}

- (void)performWithController:(RXRViewController *)controller
{

  if ([self.action isEqualToString:@"enable"] && !self.refreshControl.isRefreshing) {
    // Web 通知该页面有下拉组件
    if (!self.refreshControl) {
      self.refreshControl = [self _rxr_refreshControllerWithScrollView:controller.webView];
    }

  } else if ([self.action isEqualToString:@"complete"]) {
    // Web 通知下拉动作完成
    [self.refreshControl endRefreshing];
    self.onRefreshStart = NO;
  }
}

#pragma mark - Private

- (UIRefreshControl *)_rxr_refreshControllerWithScrollView:(UIWebView *)webView
{
  UIScrollView *scrollView = webView.scrollView;
  UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
  [scrollView addSubview:refreshControl];
  [refreshControl addTarget:self action:@selector(_rxr_refresh:) forControlEvents:UIControlEventValueChanged];
  return refreshControl;
}

- (void)_rxr_refresh:(UIRefreshControl *)refreshControl
{
  UIView *view = [[refreshControl superview] superview];
  if ([view isKindOfClass:[UIWebView class]] && !self.onRefreshStart) {
    self.onRefreshStart = YES;
    UIWebView *webView = (UIWebView *)view;
    [webView stringByEvaluatingJavaScriptFromString:@"window.Rexxar.Widget.PullToRefresh.onRefreshStart()"];
  }
}

@end
