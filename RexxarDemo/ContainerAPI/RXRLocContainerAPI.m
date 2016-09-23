//
//  RXRLocContainerAPI.m
//  Rexxar
//
//  Created by GUO Lin on 8/19/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//
#import <Rexxar/RXRContainerAPI.h>

#import "RXRLocContainerAPI.h"

@implementation RXRLocContainerAPI

- (BOOL)shouldInterceptRequest:(NSURLRequest *)request
{
  // http://rexxar-container/api/event_location
  if ([request.URL.scheme isEqualToString:@"http"] &&
      [request.URL.host isEqualToString:@"rexxar-container"] &&
      [request.URL.path hasPrefix:@"/api/event_location"]) {

    return YES;
  }
  return NO;
}

- (NSURLResponse *)responseWithRequest:(NSURLRequest *)request
{
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                            statusCode:200
                                                           HTTPVersion:@"HTTP/1.1"
                                                          headerFields:nil];
  return response;
}


- (NSData *)responseData
{
  // It's just a demo here.
  // You can implement your own loc service to get the current city data.
  NSDictionary *dictionary = @{@"name": @"北京",
                               @"letter": @"beijing",
                               @"longitude": @(116.41667),
                               @"latitude": @(39.91667)};
  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
  return jsonData;
}

@end
