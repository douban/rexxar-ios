//
//  RXRConfig.m
//  Rexxar
//
//  Created by GUO Lin on 5/30/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

@import UIKit;

#import "RXRConfig.h"
#import "RXRRouteManager.h"

@implementation RXRConfig

static NSString *sRXRProtocolScheme;
static NSString *sRXRProtocolHost;
static NSString *sRXRUserAgent;
static NSURL *sRoutesMapURL;
static NSString *sRoutesCachePath;
static NSString *sRoutesResourcePath;
static BOOL sIsCacheEnable = YES;

static NSString * const DefaultRXRScheme = @"douban";
static NSString * const DefaultRXRHost = @"rexxar-container";


+ (void)setRXRProtocolScheme:(NSString *)scheme
{
  @synchronized (self) {
    sRXRProtocolScheme = scheme;
  }
}

+ (NSString *)rxrProtocolScheme
{
  if (sRXRProtocolScheme) {
    return sRXRProtocolScheme;
  }
  return DefaultRXRScheme;
}

+ (void)setRXRProtocolHost:(NSString *)host
{
  @synchronized (self) {
    sRXRProtocolHost = host;
  }
}

+ (NSString *)rxrProtocolHost
{
  if (sRXRProtocolHost) {
    return sRXRProtocolHost;
  }
  return DefaultRXRHost;
}

+ (void)setRoutesMapURL:(NSURL *)routesMapURL
{
  @synchronized (self) {
    sRoutesMapURL = routesMapURL;
  }
}

+ (NSURL *)routesMapURL
{
  return sRoutesMapURL;
}

+ (void)setRoutesCachePath:(NSString *)routesCachePath
{
  @synchronized (self) {
    sRoutesCachePath = routesCachePath;
  }
}

+ (NSString *)routesCachePath
{
  return sRoutesCachePath;
}

+ (void)setRoutesResourcePath:(NSString *)routesResourcePath
{
  @synchronized (self) {
    sRoutesResourcePath = routesResourcePath;
  }
}

+ (NSString *)routesResourcePath
{
  return sRoutesResourcePath;
}

+ (void)setExternalUserAgent:(NSString *)externalUserAgent
{
  if ([sRXRUserAgent isEqualToString:externalUserAgent]) {
    return;
  }

  @synchronized (self) {
    sRXRUserAgent = externalUserAgent;

    NSArray<NSString *> *externalUserAgents = [externalUserAgent componentsSeparatedByString:@" "];

    NSMutableString *newUserAgent = [NSMutableString string];
    NSString *oldUserAgent = [[UIWebView new] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    if (oldUserAgent) {
      [newUserAgent appendString:oldUserAgent];
    }

    for (NSString *item in externalUserAgents) {
      if (![newUserAgent containsString:item]) {
        [newUserAgent appendFormat:@" %@", item];
      }
    }

    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent": newUserAgent}];

  }
}

+ (NSString *)externalUserAgent
{
  return sRXRUserAgent;
}

+ (void)updateConfig
{
  RXRRouteManager *routeManager = [RXRRouteManager sharedInstance];
  routeManager.routesMapURL = sRoutesMapURL;
  [routeManager setCachePath:sRoutesCachePath];
  [routeManager setResoucePath:sRoutesResourcePath];
}

+ (void)setCacheEnable:(BOOL)isCacheEnable
{
  @synchronized (self) {
    sIsCacheEnable = isCacheEnable;
  }
}

+(BOOL)isCacheEnable
{
  return sIsCacheEnable;
}

@end
