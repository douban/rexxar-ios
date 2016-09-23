//
//  NSMutableDictionary+RXRMultipleItems.h
//  Rexxar
//
//  Created by GUO Lin on 6/28/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

@import Foundation;

@interface NSMutableDictionary (RXRMultipleItems)

/**
 * 在字典以关键字添加一个元素。
 *
 * @param item 待添加的元素
 * @param aKey 关键字
 */
- (void)rxr_addItem:(id)item forKey:(id<NSCopying>)key;

@end
