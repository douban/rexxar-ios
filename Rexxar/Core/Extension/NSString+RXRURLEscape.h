//
//  NSString+RXRURLEscape.h
//  Rexxar
//
//  Created by GUO Lin on 6/28/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

@import Foundation;

@interface NSString (RXRURLEscape)

/**
 * url 字符串编码
 */
- (NSString *)rxr_encodingStringUsingURLEscape;

/**
 * url 字符串解码
 */
- (NSString *)rxr_decodingStringUsingURLEscape;

@end
