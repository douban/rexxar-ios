//
//  RXRToastWidget.m
//  Rexxar
//
//  Created by GUO Lin on 8/19/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

#import <Rexxar/NSURL+Rexxar.h>
#import <Rexxar/NSDictionary+RXRMultipleItems.h>

#import "RXRToastWidget.h"

#import "RexxarDemo-Swift.h"

@interface RXRToastWidget ()

@property (nonatomic, copy) NSString *level;
@property (nonatomic, copy) NSString *message;

@end


@implementation RXRToastWidget

- (BOOL)canPerformWithURL:(NSURL *)URL
{
  NSString *path = URL.path;
  if (path && [path isEqualToString:@"/widget/toast"]) {
    return true;
  }
  return false;
}


- (void)prepareWithURL:(NSURL *)URL
{
  NSDictionary *queryItems = [URL rxr_queryDictionary];
  self.level = [queryItems rxr_itemForKey:@"level"];
  self.message = [queryItems rxr_itemForKey:@"message"];
}

- (void)performWithController:(RXRViewController *)controller
{
  if ([self.level isEqualToString:@"info"]) {
    [FRDToast showSuccess:self.message];
  } else if ([self.level isEqualToString:@"error"]) {
    [FRDToast showInfo:self.message];
  } else if ([self.level isEqualToString:@"fatal"]) {
    [FRDToast showError:self.message];
  }
}

@end
