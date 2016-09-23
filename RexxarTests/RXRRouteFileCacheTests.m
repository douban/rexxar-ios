//
//  RXRRouteFileCacheTests.m
//  Rexxar
//
//  Created by GUO Lin on 5/12/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "RXRCacheFileIntercepter.h"
#import "RXRConfig.h"

#import "RXRRouteFileCache.h"

@interface RXRRouteFileCacheTests : XCTestCase


@end

@implementation RXRRouteFileCacheTests

- (void)setUp
{
  NSString *resourcePath = [[NSBundle bundleForClass:self.class] pathForResource:@"www" ofType:nil];
  [RXRConfig setRoutesResourcePath:resourcePath];

  [RXRConfig setRoutesCachePath:[[NSUUID UUID] UUIDString]];
  [NSURLProtocol registerClass:[RXRCacheFileIntercepter class]];
}

+ (void)tearDown
{
  [NSURLProtocol unregisterClass:[RXRCacheFileIntercepter class]];
}


- (void)testCacheJS
{
  NSURL *resourceURL = [NSURL URLWithString:@"http://img3.doubanio.com/f/shire/3d5cb5d1155d18c20ab9bd966387432a8a9f2008/js/core/_init_.js"];

  XCTestExpectation *expect = [self expectationWithDescription:@"Resource cached"];
  [[[NSURLSession sharedSession] dataTaskWithRequest:[self webResourceRequest:resourceURL]
                                   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                     if (data && [[RXRRouteFileCache sharedInstance] routeFileURLForRemoteURL:resourceURL]) {
                                       [expect fulfill];
                                     }
                                   }] resume];

  [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)testCacheCss
{
  NSURL *resourceURL = [NSURL URLWithString:@"https://img3.doubanio.com/misc/mixed_static/6f59bfb52430ee85.css"];

  XCTestExpectation *expect = [self expectationWithDescription:@"Resource cached"];
  [[[NSURLSession sharedSession] dataTaskWithRequest:[self webResourceRequest:resourceURL]
                                   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                     if (data && [[RXRRouteFileCache sharedInstance] routeFileURLForRemoteURL:resourceURL]) {
                                       [expect fulfill];
                                     }
                                   }] resume];

  [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)testNoCacheResource
{
  NSURL *resourceURL = [NSURL URLWithString:@"http://cdn.staticfile.org/jquery/2.1.1-rc2/jquery.js"];

  XCTestExpectation *expect = [self expectationWithDescription:@"Resource should not be cached"];
  [[[NSURLSession sharedSession] dataTaskWithRequest:[self webResourceRequest:resourceURL]
                                   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                     if (data && [[RXRRouteFileCache sharedInstance] routeFileURLForRemoteURL:resourceURL]) {
                                       [expect fulfill];
                                     }
                                   }] resume];

  [self waitForExpectationsWithTimeout:30 handler:nil];
}


- (NSMutableURLRequest *)webResourceRequest:(NSURL *)url
{
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [request addValue:@"Mozilla" forHTTPHeaderField:@"User-Agent"];
  return request;
}

@end
