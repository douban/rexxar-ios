//
//  RXRAlertDialogData.m
//  Rexxar
//
//  Created by GUO Lin on 6/28/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

#import "RXRAlertDialogData.h"

@implementation RXRAlertDialogButton

- (NSString *)text
{
  return [self.dictionary objectForKey:@"text"];
}

- (NSString *)action
{
  return [self.dictionary objectForKey:@"action"];
}

@end


@implementation RXRAlertDialogData

- (NSString *)title
{
  return [self.dictionary objectForKey:@"title"];
}

- (NSString *)message
{
  return [self.dictionary objectForKey:@"message"];
}

- (NSArray<RXRAlertDialogButton *> *)buttons
{
  NSMutableArray<RXRAlertDialogButton *> *result = [NSMutableArray array];
  NSArray *array = [self.dictionary objectForKey:@"buttons"];
  for (id dic in array) {
    if ([dic isKindOfClass:[NSDictionary class]]) {
      RXRAlertDialogButton *button = [[RXRAlertDialogButton alloc] initWithDictionary:dic];
      if (button) {
        [result addObject:button];
      }
    }
  }
  return result;
}

@end
