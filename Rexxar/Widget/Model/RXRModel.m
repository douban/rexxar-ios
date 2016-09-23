//
//  RXRModel.m
//  Rexxar
//
//  Created by GUO Lin on 6/28/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

#import "RXRModel.h"

@implementation RXRModel

- (id)init
{
  self = [super init];
  if (self) {
    self.dictionary = [NSMutableDictionary dictionary];
  }
  return  self;
}

- (id)initWithDictionary:(NSDictionary *)theDictionary
{
  self = [self init];
  if (self) {
    if (![theDictionary isKindOfClass:[NSDictionary class]]) {
      theDictionary = nil;
    }
    self.dictionary = [[NSMutableDictionary alloc] initWithDictionary:theDictionary];
  }
  return self;
}

- (id)initWithString:(NSString *)theJsonStr
{
  if (!theJsonStr || [theJsonStr length] <= 0) {
    return nil;
  }

  NSData *jsonStrData = [theJsonStr dataUsingEncoding:NSUTF8StringEncoding];
  if (!jsonStrData) {
    return nil;
  }

  NSError *error = nil;
  id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonStrData
                                                  options:kNilOptions
                                                    error:&error];
  if (error) {
    return nil;
  }

  NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:jsonObject];
  if (!dic) {
    return nil;
  }

  self = [self initWithDictionary:dic];

  return self;
}

- (NSString *)string
{
  if (self.dictionary) {
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.dictionary options:kNilOptions error:nil];
    NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return result;
  }
  return nil;
}

- (void)setString:(NSString *)theJsonStr
{
  NSError *error = nil;
  id jsonObject = [NSJSONSerialization JSONObjectWithData:[theJsonStr dataUsingEncoding:NSUTF8StringEncoding]
                                                  options:kNilOptions
                                                    error:&error];
  if (error) {
    return;
  }

  NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:jsonObject];
  if (!dic) {
    return;
  }
  self.dictionary = dic;
}

@end
