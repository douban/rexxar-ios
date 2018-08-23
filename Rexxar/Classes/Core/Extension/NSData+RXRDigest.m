//
//  NSData+DOUDigest.m
//  Rexxar
//
//  Created by GUO Lin on 10/04/13.
//  Copyright (c) 2013 Douban Inc. All rights reserved.
//

#import "NSData+RXRDigest.h"
#include <CommonCrypto/CommonDigest.h>

#define DOU_DIGEST_PERFORM(_LENGTH, _FUNCTION) \
  NSMutableString *result; \
  do { \
    size_t i; \
    unsigned char md[(_LENGTH)]; \
    \
    bzero(md, sizeof(md)); \
    (_FUNCTION)([self bytes], (CC_LONG)[self length], md); \
    \
    result = [NSMutableString stringWithCapacity:(_LENGTH) * 2]; \
    for (i = 0; i < (_LENGTH); ++i) { \
      [result appendFormat:@"%02x", md[i]]; \
    } \
  } while (0); \
  return [result copy]

@implementation NSData (RXRDigest)

- (NSString *)md5
{
  DOU_DIGEST_PERFORM(CC_MD5_DIGEST_LENGTH, CC_MD5);
}

- (NSString *)sha1
{
  DOU_DIGEST_PERFORM(CC_SHA1_DIGEST_LENGTH, CC_SHA1);
}

- (NSString *)sha256
{
  DOU_DIGEST_PERFORM(CC_SHA256_DIGEST_LENGTH, CC_SHA256);
}

- (NSString *)sha512
{
  DOU_DIGEST_PERFORM(CC_SHA512_DIGEST_LENGTH, CC_SHA512);
}

@end
