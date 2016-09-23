//
//  URITests.m
//  Rexxar
//
//  Created by Tony Li on 11/23/15.
//  Copyright © 2015 Douban.Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "RXRConfig.h"
#import "RXRViewController.h"

@interface UIWebView (URITests)

@property (nonatomic, readonly) NSString *representedURI;

@end

@implementation UIWebView (URITests)

- (NSString *)representedURI
{
  NSString *result = [self stringByEvaluatingJavaScriptFromString:@"get_uri()"];
  return result;
}

@end

@interface URITests : XCTestCase

@end

@implementation URITests

- (void)setUp
{
  [RXRConfig setRoutesResourcePath:[[NSBundle bundleForClass:self.class] pathForResource:@"www" ofType:nil]];
}

- (void)testSimply
{
  [self verifyURIString:@"douban://douban.com/note/123"];
}

- (void)testQuery
{
  [self verifyURIString:@"douban://douban.com/note/123?key=value"];
  [self verifyURIString:@"douban://douban.com/note/123?key=中文"];
  [self verifyURIString:@"douban://douban.com/note/123?key=中文&a=b"];
}

- (void)testComplicate
{
  [self verifyURIString:@"douban://douban.com/note/123?page=10&from=main&title=日记#中文"];
}

- (void)verifyURIString:(NSString *)uriString
{
  NSURL *uri = [[[NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil]
                 matchesInString:uriString options:0 range:NSMakeRange(0, uriString.length)].firstObject URL];
  XCTAssertNotNil(uri);
  NSURL *htmlURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"www/uri_test" withExtension:@"html"];
  XCTAssertNotNil(htmlURL);

  RXRViewController *controller = [[RXRViewController alloc] initWithURI:uri htmlFileURL:htmlURL];
  [self expectationForPredicate:[NSPredicate predicateWithFormat:@"representedURI == %@", uriString]
            evaluatedWithObject:[[[controller view] subviews] firstObject]
                        handler:nil];

  [self waitForExpectationsWithTimeout:1.5 handler:nil];
}

@end
