//
//  RouteTests.m
//  Rexxar
//
//  Created by Tony Li on 11/24/15.
//  Copyright © 2015 Douban.Inc. All rights reserved.
//
#import <XCTest/XCTest.h>

#import "RXRConfig.h"
#import "RXRRouteManager.h"
#import "RXRViewController.h"
#import "RXRRoute.h"

@interface RXRRouteManagerTests : XCTestCase


@end


@implementation RXRRouteManagerTests

- (void)setUp
{
  [RXRConfig setRoutesCachePath:[[NSUUID UUID] UUIDString]];
  NSString *resourcePath = [[NSBundle bundleForClass:self.class] pathForResource:@"www" ofType:nil];
  [RXRConfig setRoutesResourcePath:resourcePath];

  NSURL *routesMapURL = [NSURL URLWithString:@"https://rexxar.douban.com/api/routes"];;
  [RXRConfig setRoutesMapURL:routesMapURL];
}

- (void)testRoutes
{
  NSURL *uri = [NSURL URLWithString:@"douban://douban.com/subject_collection/123"];

  [RXRViewController updateRouteFilesWithCompletion:NULL];
  
  [self expectationForPredicate:[self predicateForURI:uri routable:YES]
            evaluatedWithObject:[NSObject new]
                        handler:nil];

  [self expectationForPredicate:[self predicateForURI:[NSURL URLWithString:@"douban://douban.com/foo"] routable:NO]
            evaluatedWithObject:[NSObject new]
                        handler:nil];

  [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testLocalRoutes
{
  NSString *uri = @"douban://douban.com/subject_collection/123";
  BOOL found = NO;

  NSURL *remoteHtmlURL = [[RXRRouteManager sharedInstance] remoteHtmlURLForURI:[NSURL URLWithString:uri]];
  if (remoteHtmlURL) {
    found = YES;
  }
  XCTAssertTrue(found);
}

- (NSPredicate *)predicateForURI:(NSURL *)uri routable:(BOOL)routable
{
  return [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary<NSString *,id> * bindings) {
    id instance = [[RXRRouteManager sharedInstance] remoteHtmlURLForURI:uri];
    return routable ? instance != nil : instance == nil;
  }];
}

@end
