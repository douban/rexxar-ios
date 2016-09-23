//
//  RXRMenuItem.m
//  Frodo
//
//  Created by Tony Li on 11/25/15.
//  Copyright © 2015 Douban Inc. All rights reserved.
//


#import "RXRMenuItem.h"

@implementation RXRMenuItem

- (NSString *)type
{
  return [self.dictionary objectForKey:@"type"];
}

- (NSString *)title
{
  return [self.dictionary objectForKey:@"title"];
}

- (NSString *)color
{
  return [self.dictionary objectForKey:@"color"];
}

- (NSURL *)uri
{
  return [NSURL URLWithString:[self.dictionary objectForKey:@"uri"]];
}

@end
