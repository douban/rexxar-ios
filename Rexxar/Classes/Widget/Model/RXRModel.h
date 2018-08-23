//
//  RXRModel.h
//  Rexxar
//
//  Created by GUO Lin on 6/28/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 * `RXRModel` 数据对象。
 * Web 对 Native 调用时可能会出发一些结构化的数据。
 * RXRModel 提供了对这些数据的更简便的访问方法。
 */
@interface RXRModel : NSObject

/**
 * 数据对象的 json 字符串形式。
 */
@property (nonatomic, readonly, copy) NSString *string;

/**
 * 数据对象的字典形式。
 */
@property (nonatomic, strong) NSMutableDictionary *dictionary;

/**
 * 以 json 字符串初始化数据对象。
 *
 * @param theJsonStr 字符串
 */
- (id)initWithString:(NSString *)theJsonStr;

/**
 * 以字典初始化数据对象。
 *
 * @param theDictionary 字典
 */
- (id)initWithDictionary:(NSDictionary *)theDictionary;

@end

NS_ASSUME_NONNULL_END
