//
//  RXRLogger.m
//  Rexxar
//
//  Created by bigyelow on 07/11/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

#import "RXRLogger.h"

const NSString *logOtherInfoStatusCodeKey = @"logOtherInfoStatusCodeKey";
const NSString *logOtherInfoRoutesDepolyTimeKey = @"logOtherInfoRoutesDepolyTimeKey";

static NSString *descriptionFromLogType(RXRLogType type)
{
  switch (type) {
    case RXRLogTypeNoRoutesMapURLError:
      return @"no_routes_map_url";

    case RXRLogTypeDownloadingRoutesError:
      return @"downloading_routes_error";

    case RXRLogTypeDownloadingHTMLFileError:
      return @"downloading_HTML_file_error";

    case RXRLogTypeValidatingHTMLFileError:
      return @"validating_HTML_file_error";

    case RXRLogTypeFailedToCreateCacheDirectoryError:
      return @"failed_to_create_cache_directory_error";

    case RXRLogTypeWebViewLoadingError:
      return @"webView_loading_error";

    case RXRLogTypeNoLocalHTMLForURI:
      return @"no_local_html_for_uri";

    case RXRLogTypeNoRemoteHTMLForURI:
      return @"no_remote_html_for_uri";

    case RXRLogType404:
      return @"webview_load_404";

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
