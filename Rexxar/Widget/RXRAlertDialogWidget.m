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

  NSString *title = self.alertDialogData.title;
  NSString *message = self.alertDialogData.message;
  NSArray<RXRAlertDialogButton *> *buttons = self.alertDialogData.buttons;

  if (NSClassFromString(@"UIAlertController")) {
    [self _rxr_alertWithTitle:title message:message buttons:buttons];
  } else {
    [self _rxr_ios7_alertWithTitle:title message:message buttons:buttons];
  }
}

#pragma mark - Private methods

- (void)_rxr_alertWithTitle:(NSString *)title
                    message:(NSString *)message
                    buttons:(NSArray<RXRAlertDialogButton *> *)buttons
{
  UIAlertController *alertView = [UIAlertController alertControllerWithTitle:title
                                                                     message:message
                                                              preferredStyle:UIAlertControllerStyleAlert];

  for (RXRAlertDialogButton *button in buttons) {
    UIAlertAction *action = [UIAlertAction actionWithTitle:button.text
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *alertAction)
                             {
                               [self.rexxarViewController.webView stringByEvaluatingJavaScriptFromString:button.action];
                             }];

    [alertView addAction:action];
  }

  [self.rexxarViewController presentViewController:alertView animated:YES completion:nil];
}

- (void)_rxr_ios7_alertWithTitle:(NSString *)title
                         message:(NSString *)message
                         buttons:(NSArray<RXRAlertDialogButton *> *)buttons
{
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                      message:message
                                                     delegate:self
                                            cancelButtonTitle:nil
                                            otherButtonTitles:nil, nil];

  for (RXRAlertDialogButton *button in buttons) {
    [alertView addButtonWithTitle:button.text];
  }

  [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  NSArray<RXRAlertDialogButton *> *buttons = self.alertDialogData.buttons;
  if (buttons.count < buttonIndex) {
    RXRAlertDialogButton *button = buttons[buttonIndex];
    [self.rexxarViewController.webView stringByEvaluatingJavaScriptFromString:button.action];
  }
}

@end
