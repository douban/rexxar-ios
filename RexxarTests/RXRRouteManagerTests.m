//
//  RouteTests.m
//  Rexxar
//
//  Created by Tony Li on 11/24/15.
//  Copyright © 2015 Douban.Inc. All rights reserved.
//
#import <XCTest/XCTest.h>

#import "RXRRouteManager.h"
#import "RXRRouteFileCache.h"
#import "RXRViewController.h"
#import "RXRConfig.h"
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

- (void)testCompareVersion
{
  XCTAssert([[RXRRouteManager sharedInstance] compareVersion:@"6.36.0" toVersion:@"6.36.1"] == NSOrderedAscending);
  XCTAssert([[RXRRouteManager sharedInstance] compareVersion:@"6.36.0" toVersion:@"6.36.0"] == NSOrderedSame);
  XCTAssert([[RXRRouteManager sharedInstance] compareVersion:@"6.36.0" toVersion:@"6.35.100"] == NSOrderedDescending);
  XCTAssert([[RXRRouteManager sharedInstance] compareVersion:@"6.36.4" toVersion:@"6.36.4.1"] == NSOrderedAscending);
}

- (void)testInitializeRoutesFromResource
{
  // Resource routes version: 6.4.0
  NSString *jsonWithLowVersion = @"{\"version\": \"6.3.0\", \"items\": []}";
  NSString *jsonWithNoVersion = @"{\"items\": []}";
  for (NSString *json in @[jsonWithNoVersion, jsonWithLowVersion]) {
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    [[RXRRouteFileCache sharedInstance] saveRoutesMapFile:data];

    XCTAssertNotNil([[RXRRouteFileCache sharedInstance] cacheRoutesMapFile]);
    XCTAssertNotNil([[RXRRouteFileCache sharedInstance] resourceRoutesMapFile]);

    RXRRouteManager *manager = [[RXRRouteManager alloc] init];
    manager.routesMapURL = [RXRConfig routesMapURL];

    XCTAssertNil([[RXRRouteFileCache sharedInstance] cacheRoutesMapFile]);

    XCTAssertTrue(manager.routes.count == 1);
    XCTAssertTrue([manager.routesVersion isEqualToString:@"6.4.0"]);
  }
}

- (void)testInitializeRoutesFromCache
{
  NSString *json = @"{\"version\": \"6.6.0\", \"items\": []}";
  NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
  [[RXRRouteFileCache sharedInstance] saveRoutesMapFile:data];

  RXRRouteManager *manager = [[RXRRouteManager alloc] init];
  manager.routesMapURL = [RXRConfig routesMapURL];

  XCTAssertNotNil([[RXRRouteFileCache sharedInstance] cacheRoutesMapFile]);
  XCTAssertNotNil([[RXRRouteFileCache sharedInstance] resourceRoutesMapFile]);

  XCTAssertTrue(manager.routes.count == 0);
  XCTAssertTrue([manager.routesVersion isEqualToString:@"6.6.0"]);
}

- (NSPredicate *)predicateForURI:(NSURL *)uri routable:(BOOL)routable
{
  return [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary<NSString *,id> * bindings) {
    id instance = [[RXRRouteManager sharedInstance] remoteHtmlURLForURI:uri];
    return routable ? instance != nil : instance == nil;
  }];
}

@end
