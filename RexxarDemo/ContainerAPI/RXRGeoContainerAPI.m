//
//  RXRGeoContainerAPI.m
//  Rexxar
//
//  Created by GUO Lin on 8/19/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

#import "RXRGeoContainerAPI.h"

@implementation RXRGeoContainerAPI

- (BOOL)shouldInterceptRequest:(NSURLRequest *)request
{
  // https://rexxar-container/api/event_location
  if ([request.URL rxr_isHttpOrHttps] &&
      [request.URL.host isEqualToString:@"rexxar-container"] &&
      [request.URL.path hasPrefix:@"/api/geo"]) {

    return YES;
  }
  return NO;
}

- (NSURLResponse *)responseWithRequest:(NSURLRequest *)request
{
  return [NSHTTPURLResponse rxr_responseWithURL:request.URL statusCode:200 headerFields:nil noAccessControl:YES];
}

- (NSData *)responseData
{
  // It's just a demo here.
  // You can implement your own geo service to get the real current city data.
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
