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
  NSString *query = [self query];
  if ([query length] == 0) {
    return nil;
  }

  // Replace '+' with space
  query = [query stringByReplacingOccurrencesOfString:@"+" withString:@"%20"];

  NSCharacterSet *delimiterSet = [NSCharacterSet characterSetWithCharactersInString:@"&;"];
  NSMutableDictionary *pairs = [NSMutableDictionary dictionary];

  NSScanner *scanner = [[NSScanner alloc] initWithString:query];
  while (![scanner isAtEnd]) {
    NSString *pairString = nil;
    [scanner scanUpToCharactersFromSet:delimiterSet intoString:&pairString];
    [scanner scanCharactersFromSet:delimiterSet intoString:NULL];
    NSArray *kvPair = [pairString componentsSeparatedByString:@"="];
    if (kvPair.count == 2) {
      [pairs rxr_addItem:[[kvPair objectAtIndex:1] rxr_decodingStringUsingURLEscape]
                  forKey:[[kvPair objectAtIndex:0] rxr_decodingStringUsingURLEscape]];
    }
  }

  return [pairs copy];
}

@end
