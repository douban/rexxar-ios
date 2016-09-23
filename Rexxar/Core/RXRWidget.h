//
//  RXRWidget.h
//  Frodo
//
//  Created by GUO Lin on 5/5/16.
//  Copyright © 2016 Douban Inc. All rights reserved.
//

@import Foundation;


@class RXRViewController;

NS_ASSUME_NONNULL_BEGIN
/**
 * `RXRWidget` 是一个 Widget 协议。
 * 实现 RXRWidget 协议的类将完成一个 Web 对 Native 的功能调用。
 */
@protocol RXRWidget <NSObject>

/**
 * 判断该 Widget 是否要对该 URL 做出反应。
 * 
 * @param URL 对应的 URL。
 */
- (BOOL)canPerformWithURL:(NSURL *)URL;

/**
 * 对该 URL，执行 Widget 的各项准备工作。
 *
 * @param URL 对应的 URL。
 */
- (void)prepareWithURL:(NSURL *)URL;

/**
 * 执行 Widget 的操作。
 *
 * @param controller 执行该 Widget 的 Controller。
 */
- (void)performWithController:(RXRViewController *)controller;

@end

NS_ASSUME_NONNULL_END
