//
//  RXRNavMenuWidget.m
//  RexxarDemo
//
//  Created by GUO Lin on 5/5/16.
//  Copyright © 2016 Douban Inc. All rights reserved.
//

#import <Rexxar/NSURL+Rexxar.h>
#import <Rexxar/NSDictionary+RXRMultipleItems.h>
#import <Rexxar/RXRViewController.h>

#import "RXRNavMenuWidget.h"
#import "RXRMenuItem.h"


@interface RXRNavMenuWidget ()

@property (nonatomic, copy) NSArray<RXRMenuItem *> *menuItems;

@end


@implementation RXRNavMenuWidget

- (BOOL)canPerformWithURL:(NSURL *)URL
{
  NSString *path = URL.path;
  if (path && [path isEqualToString:@"/widget/nav_menu"]) {
    return true;
  }
  return false;
}

- (void)prepareWithURL:(NSURL *)URL
{
  NSString *string = [[URL rxr_queryDictionary] rxr_itemForKey:@"data"];
  NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
  NSArray *itemJSONs = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
  if ([itemJSONs isKindOfClass:[NSArray class]] && itemJSONs.count > 0) {
    NSMutableArray *menuItems = [NSMutableArray array];
    for (id JSON in itemJSONs) {
      if ([JSON isKindOfClass:[NSDictionary class]]) {
        [menuItems addObject:[[RXRMenuItem alloc] initWithDictionary:JSON]];
      }
    }
    self.menuItems = [menuItems copy];
  }
}

- (void)performWithController:(RXRViewController *)controller
{
  if (!self.menuItems || self.menuItems.count == 0) {
    return;
  }

  NSMutableArray *items = [NSMutableArray array];
  [self.menuItems enumerateObjectsUsingBlock:^(RXRMenuItem *menu, NSUInteger idx, BOOL *stop) {
    UIBarButtonItem *item = [self _frd_buildMenuItem:menu];
    item.tag = idx;
    [items addObject:item];
  }];
  controller.navigationItem.rightBarButtonItems = items;
}


#pragma mark - Private methods

- (void)_frd_buttonItemAction:(UIBarButtonItem *)item
{
  RXRMenuItem *menu = self.menuItems[item.tag];
  NSLog(@"Action go to uri: %@", menu.uri);
}

- (UIBarButtonItem *)_frd_buildMenuItem:(RXRMenuItem *)menu
{
  UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:menu.title
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(_frd_buttonItemAction:)];
  return item;
}

@end
