//
//  FRDRXRLogContainerAPI.m
//  Frodo
//
//  Created by GUO Lin on 5/18/16.
//  Copyright © 2016 Douban Inc. All rights reserved.
//

#import "RXRLogContainerAPI.h"

@implementation RXRLogContainerAPI

- (BOOL)shouldInterceptRequest:(NSURLRequest *)request
{
  // https://rexxar-container/api/event_location
  if ([request.URL rxr_isHttpOrHttps] &&
      [request.URL.host isEqualToString:@"rexxar-container"] &&
      [request.URL.path hasPrefix:@"/api/log"] &&
      [request.HTTPMethod.uppercaseString isEqualToString:@"GET"] &&
      [request.URL.query containsString:@"_rexxar_method=POST"]) {

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
  NSDictionary *dictionary = @{};
  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                     options:NSJSONWritingPrettyPrinted
                                                       error:&error];
  return jsonData;
}

- (void)performWithRequest:(NSURLRequest *)request completion:(void (^)(void))completion
{
  NSData *data = request.HTTPBody;
  NSString *encodeStr = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
  NSString *decodeStr = [encodeStr rxr_decodingStringUsingURLEscape];

  NSArray<NSString *> *keyValues = [decodeStr componentsSeparatedByString:@"&"];
  if (keyValues.count > 0) {
    NSMutableDictionary *form = [NSMutableDictionary dictionary];
    for (NSString *keyValue in keyValues) {
      NSArray *array = [keyValue componentsSeparatedByString:@"="];
      if (array.count == 2) {
        [form setObject:array[1] forKey:array[0]];
      }
    }

    if ([form rxr_itemForKey:@"event"]) {
      NSLog(@"Log event:%@, label:%@", [form rxr_itemForKey:@"event"],  [form rxr_itemForKey:@"label"]);
    }
  }

  if (completion) {
    completion();
  }
}

@end
