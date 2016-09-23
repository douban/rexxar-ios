//
//  RexxarTests.m
//  RexxarTests
//
//  Created by Tony Li on 11/20/15.
//  Copyright © 2015 Douban.Inc. All rights reserved.
//
#import <XCTest/XCTest.h>

#import "Rexxar.h"
#import "RXRRequestIntercepter.h"
#import "RXRRouteFileManager.h"
#import "RequestDecorator.h"

@interface RexxarTests : XCTestCase

@property (nonatomic, readonly) RXRRouteFileManager *routeFileManager;
@property (nonatomic, readonly) id<RXRRequestDecorator> decorater;

@end

@implementation RexxarTests

- (void)setUp
{
  NSURL *routesMapURL = [NSURL URLWithString:@"http://rexxar.douban.com/api/routes"];
  _routeFileManager = [[RXRRouteFileManager alloc] initWithRoutesMapURL:routesMapURL
                                                         cacheDirectory:[[NSUUID UUID] UUIDString]
                                                    resourceDirectory:[NSBundle bundleForClass:self.class].bundlePath];
}

- (void)testInterceptAPI
{
  NSURL *url = [NSURL URLWithString:@"http://frodo.douban.com/jsonp/subject_collection/movie_free_stream/items?os=ios&loc_id=108288&start=0&count=18&_=1448948380006&callback=jsonp1"];
  XCTAssertTrue([RXRRequestIntercepter isRequestInterceptable:[self webResourceRequest:url]]);

  url = [NSURL URLWithString:@"http://frodo.douban.com/api/v2/recommend_feed"];
  XCTAssertTrue([RXRRequestIntercepter isRequestInterceptable:[self webResourceRequest:url]]);
}

- (NSMutableURLRequest *)webResourceRequest:(NSURL *)url
{
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [request addValue:@"Mozilla" forHTTPHeaderField:@"User-Agent"];
  return request;
}

@end

