//
//  NSMutableDictionary+RXRMultipleItems.m
//  Rexxar
//
//  Created by GUO Lin on 6/28/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

#import "NSMutableDictionary+RXRMultipleItems.h"

@implementation NSMutableDictionary (RXRMultipleItems)

- (void)rxr_addItem:(id)item forKey:(id<NSCopying>)aKey {
  if (item == nil) {
    return;
  }
  id obj = [self objectForKey:aKey];
  NSMutableArray *array = nil;
  if ([obj isKindOfClass:[NSArray class]]) {
    array = [NSMutableArray arrayWithArray:obj];
  } else {
    array = obj ? [NSMutableArray arrayWithObject:obj] : [NSMutableArray array];
  }
  [array addObject:item];
  [self setObject:[array copy] forKey:aKey];
}

@end
