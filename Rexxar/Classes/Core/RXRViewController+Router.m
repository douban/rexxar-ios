//
//  RXRViewController+Router.m
//  Rexxar
//
//  Created by GUO Lin on 5/26/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

#import "RXRViewController.h"
#import "RXRRouteManager.h"

@implementation RXRViewController (Router)

#pragma mark - Route File Interface

+ (void)updateRouteFilesWithCompletion:(void (^)(BOOL success))completion
{
  RXRRouteManager *routeManager = [RXRRouteManager sharedInstance];
  [routeManager updateRoutesWithCompletion:completion];
}

+ (BOOL)isRouteExistForURI:(NSURL *)uri
{
  RXRRouteManager *routeManager = [RXRRouteManager sharedInstance];
  NSURL *remoteHtml = [routeManager remoteHtmlURLForURI:uri];
  if (remoteHtml) {
    return YES;
  }
  return NO;
}

+ (BOOL)isLocalRouteFileExistForURI:(NSURL *)uri
{
  RXRRouteManager *routeManager = [RXRRouteManager sharedInstance];
  NSURL *localHtml = [routeManager localHtmlURLForURI:uri];
  if (localHtml) {
    return YES;
  }
  return NO;
}

@end
