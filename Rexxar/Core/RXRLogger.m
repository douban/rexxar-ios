//
//  RXRLogger.m
//  Rexxar
//
//  Created by bigyelow on 07/11/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

#import "RXRLogger.h"

const NSString *logOtherInfoStatusCodeKey = @"logOtherInfoStatusCodeKey";

static NSString *descriptionFromLogType(RXRLogType type)
{
  switch (type) {
    case RXRLogTypeNoRoutesMapURLError:
      return @"No RoutesMapURL";

    case RXRLogTypeDownloadingRoutesError:
      return @"Downloading routes error";

    case RXRLogTypeDownloadingHTMLFileError:
      return @"Downloading HTML file error";

    case RXRLogTypeValidatingHTMLFileError:
      return @"Validating HTML file error";

    case RXRLogTypeFailedToCreateCacheDirectoryError:
      return @"Failed to create cache directory error";

    case RXRLogTypeWebViewLoadingError:
      return @"WebView loading error";

    default:
      return @"Unknow rexxar error";
  }
}

@implementation RXRLogObject

- (instancetype)init
{
  NSAssert(NO, @"Should call designated initializer");
  
  return [self initWithLogDescription:nil
                                error:nil
                           requestURL:nil
                        localFilePath:nil
                     otherInformation:nil];
}

- (instancetype)initWithLogType:(RXRLogType)type
                          error:(NSError *)error
                     requestURL:(NSURL *)requestURL
                  localFilePath:(NSString *)localFilePath
               otherInformation:(NSDictionary *)otherInformation
{
  if (self = [self initWithLogDescription:descriptionFromLogType(type)
                                    error:error
                               requestURL:requestURL
                            localFilePath:localFilePath
                          otherInformation:otherInformation]) {
    _type = type;
  }

  return self;
}

- (instancetype)initWithLogDescription:(NSString *)description
                                 error:(NSError *)error
                            requestURL:(NSURL *)requestURL
                         localFilePath:(NSString *)localFilePath
                      otherInformation:(NSDictionary *)otherInformation
{
  if (self = [super init]) {
    _logDescription = [description copy];
    _error = error;
    _requestURL = [requestURL copy];
    _localFilePath = [localFilePath copy];
    _otherInfomation = [otherInformation copy];
    _type = RXRLogTypeUnknown;
  }

  return self;
}
@end
