//
//  NSDictionary+RXRMultipleItems.m
//  Rexxar
//
//  Created by GUO Lin on 6/28/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

#import "NSDictionary+RXRMultipleItems.h"

@implementation NSDictionary (RXRMultipleItems)

- (id)rxr_itemForKey:(id)key {
  id obj = [self objectForKey:key];
  if ([obj isKindOfClass:[NSArray class]]) {
    return [obj count] > 0 ? [obj objectAtIndex:0] : nil;
  } else {
    return obj;
  }
}

- (NSArray *)rxr_allItemsForKey:(id)key {
  id obj = [self objectForKey:key];
  return [obj isKindOfClass:[NSArray class]] ? obj : (obj ? [NSArray arrayWithObject:obj] : nil);
}

@end
