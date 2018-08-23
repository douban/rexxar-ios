//
//  NSURLRequest+Rexxar.m
//  MTURLProtocol
//
//  Created by bigyelow on 2018/8/23.
//

@import MTURLProtocol;
#import "NSURLRequest+Rexxar.h"

@implementation NSURLRequest (Rexxar)

- (BOOL)rxr_isCacheFileRequest
{
  // 不是 HTTP 请求，不处理
  if (![self mt_isHTTPSeries]) {
    return NO;
  }

  // 请求不是来自浏览器，不处理
  if (![self.allHTTPHeaderFields[@"User-Agent"] hasPrefix:@"Mozilla"]) {
    return NO;
  }

  NSString *extension = self.URL.pathExtension;
  if ([extension isEqualToString:@"js"] ||
      [extension isEqualToString:@"css"] ||
      [extension isEqualToString:@"html"]) {
    return YES;
  }
  return NO;
}

@end
