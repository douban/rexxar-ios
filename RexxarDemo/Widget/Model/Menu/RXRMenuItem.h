//
//  RXRMenuItem.h
//  Frodo
//
//  Created by Tony Li on 11/25/15.
//  Copyright © 2015 Douban Inc. All rights reserved.
//

@import UIKit;

#import <Rexxar/RXRModel.h>

@interface RXRMenuItem : RXRModel

@property (nonatomic, copy, readonly) NSString *type;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) UIColor *color;
@property (nonatomic, copy, readonly) NSURL *uri;

@end
