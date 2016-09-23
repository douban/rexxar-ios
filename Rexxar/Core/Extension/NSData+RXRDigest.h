//
//  NSData+RXRDigest.h
//  Rexxar
//
//  Created by GUO Lin on 11/10/15.
//  Copyright © 2015 Douban.Inc. All rights reserved.
//

@import Foundation;

@interface NSData (RXRDigest)

- (NSString *)md5;
- (NSString *)sha1;
- (NSString *)sha256;
- (NSString *)sha512;

@end
