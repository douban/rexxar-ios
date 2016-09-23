//
//  RXRNavTitleWidget.m
//  Frodo
//
//  Created by GUO Lin on 5/5/16.
//  Copyright © 2016 Douban Inc. All rights reserved.
//

#import "RXRNavTitleWidget.h"
#import "RXRViewController.h"
#import "NSDictionary+RXRMultipleItems.h"
#import "NSURL+Rexxar.h"

@interface RXRNavTitleWidget ()

@property (nonatomic, copy) NSString *title;

@end


@implementation RXRNavTitleWidget

- (BOOL)canPerformWithURL:(NSURL *)URL
{
  NSString *path = URL.path;
  if (path && [path isEqualToString:@"/widget/nav_title"]) {
    return YES;
  }
  return NO;
}

- (void)prepareWithURL:(NSURL *)URL
{
  self.title = [[URL rxr_queryDictionary] rxr_itemForKey:@"title"];
}

- (void)performWithController:(RXRViewController *)controller
{
  if (controller) {
    controller.title = self.title;
  }
}

@end
