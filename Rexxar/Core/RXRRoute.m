//
//  RXRRoute.m
//  Rexxar
//
//  Created by Tony Li on 11/20/15.
//  Copyright © 2015 Douban.Inc. All rights reserved.
//

#import "RXRRoute.h"

@implementation RXRRoute

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
  if ( (self = [super init]) ) {
    _remoteHTML = [NSURL URLWithString:dict[@"remote_file"]];
    _URIRegex = [NSRegularExpression regularExpressionWithPattern:dict[@"uri"] options:0 error:nil];
  }
  return self;
}

@end
