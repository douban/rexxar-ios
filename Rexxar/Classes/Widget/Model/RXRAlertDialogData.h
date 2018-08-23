//
//  RXRAlertDialogData.h
//  Rexxar
//
//  Created by GUO Lin on 6/28/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

#import "RXRModel.h"

/**
 * `RXRAlertDialogButton` 对话框上按钮的数据对象。
 */
@interface RXRAlertDialogButton : RXRModel

/**
 * 按钮的标题文字。
 */
@property (nonatomic, copy, readonly) NSString *text;

/**
 * 按按钮后将执行的动作。
 */
@property (nonatomic, copy, readonly) NSString *action;

@end

/**
 * `RXRAlertDialogData` 对话框的数据对象。
 */
@interface RXRAlertDialogData : RXRModel

/**
 * 对话框的标题。
 */
@property (nonatomic, copy, readonly) NSString *title;

/**
 * 对话框的消息。
 */
@property (nonatomic, copy, readonly) NSString *message;

/**
 * 对话框的按钮。
 */
@property (nonatomic, readonly) NSArray<RXRAlertDialogButton *> *buttons;

@end
