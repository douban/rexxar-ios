//
//  NSURL+Rexxar.m
//  Rexxar
//
//  Created by GUO Lin on 1/18/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

#import "NSURL+Rexxar.h"
#import "NSString+RXRURLEscape.h"
#import "NSMutableDictionary+RXRMultipleItems.h"

@implementation NSURL (Rexxar)

+ (NSString *)rxr_queryFromDictionary:(NSDictionary *)dict
{
  NSMutableArray *pairs = [NSMutableArray array];
  [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
    [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, obj]];
  }];

  NSString *query = nil;
  if (pairs.count > 0) {
    query = [pairs componentsJoinedByString:@"&"];
  }
  return query;
}

- (BOOL)rxr_isHttpOrHttps
{
  if ([self.scheme caseInsensitiveCompare:@"http"] == NSOrderedSame ||
      [self.scheme caseInsensitiveCompare:@"https"] == NSOrderedSame) {
    return YES;
  }
  return NO;
}

- (NSDictionary *)rxr_queryDictionary {
  NSArray *queryItems = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES].queryItems;
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  for (NSURLQueryItem *item in queryItems) {
    if (item.name && item.value) {
      [dict rxr_addItem:item.value forKey:item.name];
    }
  }

  return dict;
}

@end
