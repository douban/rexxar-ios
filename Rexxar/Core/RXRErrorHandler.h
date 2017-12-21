//
//  RXRErrorHandler.h
//  Rexxar
//
//  Created by bigyelow on 21/12/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT const NSString * _Nonnull errorUserInfoURLKey;

@protocol RXRErrorHandler <NSObject>
- (void)reporter:(nullable id)reporter didReceiveError:(nullable NSError *)error;
@end
