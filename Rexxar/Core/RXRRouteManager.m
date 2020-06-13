//
//  RXRRouteManager.m
//  Rexxar
//
//  Created by GUO Lin on 5/11/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RXRRouteManager.h"
#import "RXRRouteFileCache.h"
#import "RXRConfig.h"
#import "RXRConfig+Rexxar.h"
#import "RXRRoute.h"
#import "RXRLogger.h"

@interface RXRRoutesObject : NSObject

@property (nonatomic, copy) NSArray<RXRRoute *> *routes;
@property (nonatomic, copy) NSString *deployTime;
@property (nonatomic, copy) NSString *version;

@end

@implementation RXRRoutesObject

@end

@interface RXRRouteManager ()

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;
@property (nonatomic, strong) NSOperationQueue *sessionDelegateQueue;

@property (nonatomic, copy) NSArray<RXRRoute *> *routes;
@property (nonatomic, copy) NSString *routesVersion;
@property (nonatomic, assign) BOOL updatingRoutes;
@property (nonatomic, strong) NSMutableArray *updateRoutesCompletions;

@end


@implementation RXRRouteManager

+ (RXRRouteManager *)sharedInstance
{
  static RXRRouteManager *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[RXRRouteManager alloc] init];
    instance.routesMapURL = [RXRConfig routesMapURL];
  });
  return instance;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    NSString *sessionName = [NSString stringWithFormat:@"%@.%@.%p.URLSession", [[NSBundle mainBundle] bundleIdentifier], NSStringFromClass([self class]), self];
    NSString *delegateQueueName = [NSString stringWithFormat:@"%@.delegateQueue", sessionName];
    _sessionConfiguration = [[RXRConfig requestsURLSessionConfiguration] copy];
    _sessionDelegateQueue = [[NSOperationQueue alloc] init];
    _sessionDelegateQueue.maxConcurrentOperationCount = 1;
    _sessionDelegateQueue.name = delegateQueueName;
    _session = [NSURLSession sessionWithConfiguration:_sessionConfiguration delegate:nil delegateQueue:_sessionDelegateQueue];
    _session.sessionDescription = sessionName;
    _updateRoutesCompletions = [NSMutableArray array];
  }
  return self;
}

- (void)setRoutesMapURL:(NSURL *)routesMapURL
{
  if (_routesMapURL != routesMapURL) {
    _routesMapURL = [routesMapURL copy];
    [self _rxr_initializeRoutesFromLocalFiles];
  }
}

- (void)setCachePath:(NSString *)cachePath
{
  RXRRouteFileCache *routeFileCache = [RXRRouteFileCache sharedInstance];
  routeFileCache.cachePath = cachePath;
  [self _rxr_initializeRoutesFromLocalFiles];
}

- (void)setResoucePath:(NSString *)resourcePath
{
  RXRRouteFileCache *routeFileCache = [RXRRouteFileCache sharedInstance];
  routeFileCache.resourcePath = resourcePath;
  [self _rxr_initializeRoutesFromLocalFiles];
}

- (void)updateRoutesWithCompletion:(void (^)(BOOL success))completion
{
  NSParameterAssert([NSThread isMainThread]);

  if (self.routesMapURL == nil) {
    RXRDebugLog(@"[Warning] `routesRemoteURL` not set.");
    [RXRConfig rxr_logWithType:RXRLogTypeNoRoutesMapURLError error:nil requestURL:nil localFilePath:nil userInfo:nil];
    return;
  }

  if (completion) {
    [self.updateRoutesCompletions addObject:completion];
  }

  if (self.updatingRoutes) {
    return;
  }

  self.updatingRoutes = YES;

  void (^APICompletion)(BOOL) = ^(BOOL success){
    dispatch_async(dispatch_get_main_queue(), ^{
      for (void (^item)(BOOL) in self.updateRoutesCompletions) {
        item(success);
      }
      [self.updateRoutesCompletions removeAllObjects];
      self.updatingRoutes = NO;
    });
  };

  // 请求路由表 API
  NSURL *routesURL = self.routesMapURL;
  if ([RXRConfig extraRequestParams].count > 0) {
    NSURLComponents *comps = [NSURLComponents componentsWithURL:routesURL resolvingAgainstBaseURL:YES];
    NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray<NSURLQueryItem *> array];
    if ([comps.queryItems count] > 0) {
      [queryItems addObjectsFromArray:comps.queryItems];
    }
    [queryItems addObjectsFromArray:[RXRConfig extraRequestParams]];
    comps.queryItems = queryItems;
    routesURL = comps.URL;
  }

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:routesURL
                                                         cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                     timeoutInterval:60];
  // 更新 Http UserAgent Header
  NSString *userAgent = [RXRConfig userAgent];
  if (userAgent) {
    [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
  }

  [[self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    RXRDebugLog(@"Download %@", response.URL);
    RXRDebugLog(@"Response: %@", response);

    NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
    if (statusCode != 200) {
      APICompletion(NO);
      NSDictionary *userInfo = @{logOtherInfoStatusCodeKey: @(statusCode)};
      [RXRConfig rxr_logWithType:RXRLogTypeDownloadingRoutesError error:error requestURL:request.URL localFilePath:nil userInfo:userInfo];
      return;
    }

    // 如果下载的 routes version 早于当前的 version，则不更新
    RXRRoutesObject *routesObject = [self _rxr_routesObjectWithData:data];

    if (![RXRConfig needsIgnoreRoutesVersion]) {
      if (routesObject.version.length > 0 && self.routesVersion.length > 0 && [self compareVersion:self.routesVersion toVersion:routesObject.version] != NSOrderedAscending) {
        APICompletion(NO);
        return;
      }
    }

    // 立即更新 `routes.json` 及内存中的 `routes`。
    if (routesObject.routes.count > 0) {
      self.routes = routesObject.routes;
      self.routesVersion = routesObject.version;
      RXRRouteFileCache *routeFileCache = [RXRRouteFileCache sharedInstance];
      [routeFileCache saveRoutesMapFile:data];
    }

    APICompletion(routesObject.routes.count > 0);
    [self _rxr_prefetchCommonUsedFilesWithinRoutes:routesObject.routes];
  }] resume];
}

- (NSURL *)localHtmlURLForURI:(NSURL *)uri
{
  NSURL *remoteHtmlURL = [self remoteHtmlURLForURI:uri];
  RXRRouteFileCache *routeFileCache = [RXRRouteFileCache sharedInstance];
  return [routeFileCache routeFileURLForRemoteURL:remoteHtmlURL];
}

- (NSURL *)remoteHtmlURLForURI:(NSURL *)uri
{
  RXRRoute *route = [self _rxr_routeForURI:uri];
  if (route) {
    return  route.remoteHTML;
  }
  return nil;
}

#pragma mark - Private Methods

- (RXRRoute *)_rxr_routeForURI:(NSURL *)uri
{
  NSString *uriString = uri.absoluteString;
  if (uriString.length == 0) {
    return nil;
  }

  // 从路由表中找到符合 URI 的 Route。
  for (RXRRoute *route in self.routes) {
    if ([route.URIRegex numberOfMatchesInString:uriString options:0 range:NSMakeRange(0, uriString.length)] > 0) {
      return route;
    }
  }
  return nil;
}

- (RXRRoutesObject *)_rxr_routesObjectWithData:(NSData *)data
{
  if (data == nil) {
    return nil;
  }

  NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
  if (JSON == nil) {
    return nil;
  }

  RXRRoutesObject *routesObject = [[RXRRoutesObject alloc] init];
  NSMutableArray *items = [[NSMutableArray alloc] init];
  // 页面级别的 route
  for (NSDictionary *item in JSON[@"items"]) {
    [items addObject:[[RXRRoute alloc] initWithDictionary:item]];
  }

  // 局部页面的 route
  for (NSDictionary *item in JSON[@"partial_items"]) {
    [items addObject:[[RXRRoute alloc] initWithDictionary:item]];
  }

  NSString *routesDepolyTime = JSON[@"deploy_time"];
  if (routesDepolyTime) {
    routesObject.deployTime = [routesDepolyTime copy];
  }

  NSString *version = JSON[@"version"];
  if ([version isKindOfClass:[NSString class]] && [version length] > 0) {
    routesObject.version = version;
  }

  routesObject.routes = items;
  return routesObject;
}

/**
 *  从本地缓存或预置的资源中初始化 routes，如果两者都存在，比较 routes 版本，优先使用高版本 routes
 *  如果本地缓存中的 routes 版本较小，则自动清理掉。
 */
- (void)_rxr_initializeRoutesFromLocalFiles
{
  RXRRoutesObject *cacheRoutesObject = nil;
  NSData *cacheRoutesData = [[RXRRouteFileCache sharedInstance] cacheRoutesMapFile];
  if ([cacheRoutesData length] > 0) {
    cacheRoutesObject = [self _rxr_routesObjectWithData:cacheRoutesData];
  }

  RXRRoutesObject *resourceRoutesObject = nil;
  NSData *resourceRoutesData = [[RXRRouteFileCache sharedInstance] resourceRoutesMapFile];
  if ([resourceRoutesData length] > 0) {
    resourceRoutesObject = [self _rxr_routesObjectWithData:resourceRoutesData];
  }

  RXRRoutesObject *routesObject = nil;
  if (cacheRoutesObject && resourceRoutesObject) {
    if (cacheRoutesObject.version.length > 0 && resourceRoutesObject.version.length > 0) {
      NSComparisonResult result = [self compareVersion:cacheRoutesObject.version toVersion:resourceRoutesObject.version];
      if (result == NSOrderedAscending) {
        routesObject = resourceRoutesObject;
        [[RXRRouteFileCache sharedInstance] cleanCache];
      } else {
        routesObject = cacheRoutesObject;
      }
    } else {
      routesObject = cacheRoutesObject;
    }
  } else if (cacheRoutesObject) {
    routesObject = cacheRoutesObject;
  } else if (resourceRoutesObject) {
    routesObject = resourceRoutesObject;
  }

  NSAssert(routesObject != nil, @"Routes should not be nil");
  if (routesObject) {
    self.routes = routesObject.routes;
    self.routesVersion = routesObject.version;
  }
}

/**
 *  下载 `routes` 中常用的资源文件。
 */
- (void)_rxr_prefetchCommonUsedFilesWithinRoutes:(NSArray<RXRRoute *> *)routes
{
  static BOOL isRuning = NO;
  static NSLock *lock;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    lock = [[NSLock alloc] init];
  });

  [lock lock];
  if (isRuning) {
    [lock unlock];
    return;
  }

  isRuning = YES;
  [lock unlock];

  NSMutableSet<NSURL *> *htmlURLs = [NSMutableSet<NSURL *> set];
  dispatch_group_t downloadGroup = dispatch_group_create();

  for (RXRRoute *route in routes) {
    if (!route.isPackageInApp) {
      continue;
    }

    // 如果文件在本地文件存在（要么在缓存，要么在资源文件夹），什么都不需要做
    if ([[RXRRouteFileCache sharedInstance] routeFileURLForRemoteURL:route.remoteHTML]) {
      continue;
    }

    if ([htmlURLs containsObject:route.remoteHTML]) {
      RXRDebugLog(@"Download %@ abort! Alread in download queue.", route.remoteHTML);
      continue;
    }

    dispatch_group_enter(downloadGroup);
    [htmlURLs addObject:route.remoteHTML];

    // 文件不存在，下载下来。
    NSURLRequest *request = [NSURLRequest requestWithURL:route.remoteHTML
                                             cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                         timeoutInterval:60];
    [[self.session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
      RXRDebugLog(@"Download %@", response.URL);
      RXRDebugLog(@"Response: %@", response);

      NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
      if (error || statusCode != 200) {
        // Log
        NSDictionary *userInfo = @{logOtherInfoStatusCodeKey: @(statusCode)};
        [RXRConfig rxr_logWithType:RXRLogTypeDownloadingHTMLFileError error:error requestURL:request.URL localFilePath:nil userInfo:userInfo];
        dispatch_group_leave(downloadGroup);
        RXRDebugLog(@"Fail to download remote html: %@", error);
        return;
      }

      NSData *data = [NSData dataWithContentsOfURL:location];

      // Validate data
      if (self.dataValidator
          && [self.dataValidator respondsToSelector:@selector(validateRemoteHTMLFile:fileData:)]
          && ![self.dataValidator validateRemoteHTMLFile:route.remoteHTML fileData:data]) {
        // Log
        [RXRConfig rxr_logWithType:RXRLogTypeValidatingHTMLFileError error:nil requestURL:route.remoteHTML localFilePath:nil userInfo:nil];

        if ([self.dataValidator respondsToSelector:@selector(stopDownloadingIfValidationFailed)] &&
            [self.dataValidator stopDownloadingIfValidationFailed]) {
          dispatch_group_leave(downloadGroup);
          return;
        }
      }

      [[RXRRouteFileCache sharedInstance] saveRouteFileData:data withRemoteURL:response.URL];

      dispatch_group_leave(downloadGroup);
    }] resume];
  }

  dispatch_group_notify(downloadGroup, dispatch_get_main_queue(), ^{
    [lock lock];
    isRuning = NO;
    [lock unlock];
  });
}

- (NSComparisonResult)compareVersion:(NSString *)version1 toVersion:(NSString *)version2
{
  NSParameterAssert(version1.length > 0);
  NSParameterAssert(version2.length > 0);
  NSArray *comp1 = [version1 componentsSeparatedByString:@"."];
  NSArray *comp2 = [version2 componentsSeparatedByString:@"."];
  for (NSInteger idx = 0; idx < comp1.count || idx < comp2.count; idx++) {
    NSInteger a = 0, b = 0;
    if (idx < comp1.count) {
      a = [comp1[idx] integerValue];
    }
    if (idx < comp2.count) {
      b = [comp2[idx] integerValue];
    }
    if (a > b) {
      return NSOrderedDescending;
    } else if (a < b) {
      return NSOrderedAscending;
    }
  }
  return NSOrderedSame;
}

@end
