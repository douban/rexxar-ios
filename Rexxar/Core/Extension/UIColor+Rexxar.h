//
//  UIColor+Rexxar.h
//  Rexxar
//
//  Created by Tony Li on 12/9/15.
//  Copyright © 2015 Douban.Inc. All rights reserved.
//

@import UIKit;

@interface UIColor (Rexxar)

/**
 * 字符串形式创建的 UIColor。
 *
 * @param colorComponents 颜色的字符串，颜色格式：rgba(0,0,0,0)。
 */
+ (instancetype)rxr_colorWithComponent:(NSString *)colorComponents;

@end
