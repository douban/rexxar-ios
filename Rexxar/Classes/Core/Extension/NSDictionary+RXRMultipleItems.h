//
//  NSDictionary+RXRMultipleItems.h
//  Rexxar
//
//  Created by GUO Lin on 6/28/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

@import Foundation;

@interface NSDictionary (RXRMultipleItems)

/**
 * 字典对应关键字的元素，该元素如果是数组，返回数组的首个元素。
 *
 * Return the first item of array for the specificed key.
 * -[NSDictionary objectForKey:] will return an object or an array depending on how the NSDictionary is created.
 *
 * @param key 关键字
 */
- (id)rxr_itemForKey:(id)key;

/**
 * 字典对应该关键字的元素，该元素如果是数组，返回该数组。
 *
 * Return a NSArray object which contains all the items for specificed key.
 * -[NSDictionary objectForKey:] will return an object or an array depending on how the NSDictionary is created.
 *
 * @param key 关键字
 */
- (NSArray *)rxr_allItemsForKey:(id)key;

@end
