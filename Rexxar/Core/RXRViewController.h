//
//  RXRViewController.h
//  Rexxar
//
//  Created by Tony Li on 11/4/15.
//  Copyright © 2015 Douban Inc. All rights reserved.
//

@import UIKit;

@protocol RXRWidget;

NS_ASSUME_NONNULL_BEGIN

/**
 * `RXRViewController` 是一个 Rexxar Container。
 * 它提供了一个使用 web 技术 html, css, javascript 开发 UI 界面的容器。
 */
@interface RXRViewController : UIViewController <UIWebViewDelegate>

/**
 * 对应的 uri。
 */
@property (nonatomic, strong, readonly) NSURL *uri;

/**
 * 内置的 WebView。
 */
@property (nonatomic, strong, readonly) UIWebView *webView;

/**
 * activities 代表该 Rexxar Container 可以响应的协议。
 */
@property (nonatomic, strong) NSArray<id<RXRWidget>> *widgets;

/**
 * 初始化一个RXRViewController。
 *
 * @param uri 该页面对应的 uri。
 *
 * @discussion 会根据 uri 从 Route Map File 中选择对应本地 html 文件加载。如果无本地 html 文件，则从服务器加载 html 资源。
 * 在 UIWebView 中，远程 URL 需要注意跨域问题。
 */
- (instancetype)initWithURI:(NSURL *)uri;

/**
 * 初始化一个RXRViewController。
 *
 * @param uri 该页面对应的 uri。
 * @param htmlFileURL 该页面对应的 html file url。
 *
 * @discussion 会根据 uri 从 Route Map File 中选择对应本地 html 文件加载。如果无本地 html 文件，则从服务器加载 html 资源。
 * 在 UIWebView 中，远程 URL 需要注意跨域问题。
 */
- (instancetype)initWithURI:(NSURL *)uri htmlFileURL:(NSURL *)htmlFileURL;

/**
 * 重新加载 WebView。 
 */
- (void)reloadWebView;

/**
 * 通知 WebView 页面显示，缺省会在 viewWillAppear 里调用。本方法可以由业务层自主定制向 WebView 通知 onPageVisible 的时机。
 */
- (void)onPageVisible;

/**
 * 通知 WebView 页面消失，缺省会在 viewDidDisappear 里调用。本方法可以由业务层自主定制向 WebView 通知 onPageInvisible 的时机。
 */
- (void)onPageInvisible;

@end


#pragma mark - Public Route Methods

/**
 * 暴露出 Route 相关的接口。
 */
@interface RXRViewController (Router)

/**
 * 更新 Route Files。
 *
 * @param completion 更新完成后将执行这个 block。
 */
+ (void)updateRouteFilesWithCompletion:(nullable void (^)(BOOL success))completion;

/**
 * 判断存在对应于 uri 的 route 信息
 *
 * @param uri 待判断的 uri
 */
+ (BOOL)isRouteExistForURI:(NSURL *)uri;

/**
 * 判断存在对应于 uri 的 route 信息
 *
 * @param uri 待判断的 uri
 */
+ (BOOL)isLocalRouteFileExistForURI:(NSURL *)uri;

@end

NS_ASSUME_NONNULL_END
