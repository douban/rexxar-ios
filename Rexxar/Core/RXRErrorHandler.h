//
//  RXRErrorHandler.h
//  Rexxar
//
//  Created by bigyelow on 21/12/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RXRErrorHandler <NSObject>
- (void)reporter:(id)reporter didReceiveError:(NSError *)error;
@end
