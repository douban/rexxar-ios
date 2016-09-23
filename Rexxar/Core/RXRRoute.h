//
//  RXRRoute.h
//  Rexxar
//
//  Created by Tony Li on 11/20/15.
//  Copyright © 2015 Douban.Inc. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 * `RXRRoute` 路由信息对象。
 */
@interface RXRRoute : NSObject

/**
 * 以一个字典初始化路由信息对象。
 */
- (instancetype)initWithDictionary:(NSDictionary *)dict;

/**
 * 匹配该路由的 URI 正则表达式。
 */
@property (nonatomic, readonly) NSRegularExpression *URIRegex;

/**
 * 该路由对于的 html 文件地址。
 */
@property (nonatomic, readonly) NSURL *remoteHTML;

@end

NS_ASSUME_NONNULL_END
