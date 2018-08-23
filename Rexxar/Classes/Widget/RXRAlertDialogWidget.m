//
//  RXRAlertDialogWidget.m
//  Frodo
//
//  Created by GUO Lin on 5/6/16.
//  Copyright © 2016 Douban Inc. All rights reserved.
//

#import "RXRAlertDialogWidget.h"
#import "RXRViewController.h"
#import "RXRAlertDialogData.h"
#import "NSDictionary+RXRMultipleItems.h"
#import "NSURL+Rexxar.h"

@interface RXRAlertDialogWidget ()

@property (nonatomic, weak) RXRViewController *rexxarViewController;
@property (nonatomic, strong) RXRAlertDialogData *alertDialogData;

@end


@implementation RXRAlertDialogWidget

- (BOOL)canPerformWithURL:(NSURL *)URL
{
  NSString *path = URL.path;
  if (path && [path isEqualToString:@"/widget/alert_dialog"]) {
    return YES;
  }
  return NO;
}

- (void)prepareWithURL:(NSURL *)URL
{
  NSString *string = [[URL rxr_queryDictionary] rxr_itemForKey:@"data"];
  self.alertDialogData = [[RXRAlertDialogData alloc] initWithString:string];
}

- (void)performWithController:(RXRViewController *)controller
{

  self.rexxarViewController = controller;

  if (!self.alertDialogData) {
    return;
  }

  __weak typeof(self) weakSelf = self;

  UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.alertDialogData.title
                                                                 message:self.alertDialogData.message
                                                          preferredStyle:UIAlertControllerStyleAlert];

  for (RXRAlertDialogButton *button in [self.alertDialogData buttons]) {
    UIAlertAction *action = [UIAlertAction actionWithTitle:button.text
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *alertAction) {
                                                     [weakSelf.rexxarViewController.webView evaluateJavaScript:button.action completionHandler:nil];
                                                   }];
    [alert addAction:action];
  }

  [self.rexxarViewController presentViewController:alert animated:YES completion:nil];
}

@end
