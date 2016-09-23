//
//  RXRRouteFileCache.m
//  Rexxar
//
//  Created by GUO Lin on 5/11/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

#import "RXRRouteFileCache.h"
#import "RXRConfig.h"

#import "RXRLogging.h"
#import "NSData+RXRDigest.h"

static NSString * const RoutesMapFile = @"routes.json";

@implementation RXRRouteFileCache

+ (RXRRouteFileCache *)sharedInstance
{
  static RXRRouteFileCache *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[RXRRouteFileCache alloc] init];
    instance.cachePath = [RXRConfig routesCachePath];
    instance.resourcePath = [RXRConfig routesResourcePath];
  });
  return instance;
}

- (instancetype)initWithCachePath:(NSString *)cachePath
                     resourcePath:(NSString *)resourcePath
{
  self = [super init];
  if (self) {
  }
  return self;
}

#pragma mark - Save & Read methods

- (void)setCachePath:(NSString *)cachePath
{
  // cache dir
  if (!cachePath) {
    // 默认缓存路径：<Cache>/<bundle identifier>.rexxar
    cachePath = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingString:@".rexxar"];
  }

  if (![cachePath isAbsolutePath]) {
    cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)
                  firstObject] stringByAppendingPathComponent:cachePath];
  }

  _cachePath = [cachePath copy];

  NSError *error;
  [[NSFileManager defaultManager] createDirectoryAtPath:_cachePath
                            withIntermediateDirectories:YES
                                             attributes:@{}
                                                  error:&error];
  if (error) {
    RXRDebugLog(@"Failed to create directory: %@", _cachePath);
  }
}

- (void)setResourcePath:(NSString *)resourcePath
{
  // resource dir
  if (!resourcePath && [resourcePath length] > 0) {
    // 默认资源路径：<Bundle>/rexxar
    resourcePath = [[NSBundle mainBundle] pathForResource:@"rexxar" ofType:nil];
  }

  if (![resourcePath isAbsolutePath]) {
    resourcePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:resourcePath];
  }
  _resourcePath = [resourcePath copy];
}

- (void)cleanCache
{
  NSFileManager *manager = [NSFileManager defaultManager];
  [manager removeItemAtPath:self.cachePath error:nil];
  [manager createDirectoryAtPath:self.cachePath
     withIntermediateDirectories:YES
                      attributes:@{}
                           error:NULL];
}

- (void)saveRoutesMapFile:(NSData *)data
{
  NSString *filePath = [self.cachePath stringByAppendingPathComponent:RoutesMapFile];
  if (data == nil) {
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
  } else {
    [data writeToFile:filePath atomically:YES];
  }
}

- (NSData *)routesMapFile
{
  NSString *filePath = [self.cachePath stringByAppendingPathComponent:RoutesMapFile];
  if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    return [NSData dataWithContentsOfFile:filePath];
  }

  filePath = [self.resourcePath stringByAppendingPathComponent:RoutesMapFile];
  if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    return [NSData dataWithContentsOfFile:filePath];
  }

  return nil;
}

- (void)saveRouteFileData:(NSData *)data withRemoteURL:(NSURL *)url
{
  NSString *filePath = [self _rxr_cachedRouteFilePathForRemoteURL:url];
  if (data == nil) {
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
  } else {
    [data writeToFile:filePath atomically:YES];
  }
}

- (NSData *)routeFileDataForRemoteURL:(NSURL *)url
{
  NSString *filePath = [self routeFilePathForRemoteURL:url];
  if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    return [NSData dataWithContentsOfFile:filePath];
  }

  return nil;
}

- (NSString *)routeFilePathForRemoteURL:(NSURL *)url
{
  NSString *filePath = [self _rxr_cachedRouteFilePathForRemoteURL:url];
  if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    return filePath;
  }

  filePath = [self _rxr_resourceRouteFilePathForRemoteURL:url];
  if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    return filePath;
  }

  return nil;
}

- (NSURL *)routeFileURLForRemoteURL:(NSURL *)url
{
  if (url == nil) {
    return nil;
  }

  NSString *filePath = [self routeFilePathForRemoteURL:url];
  return [[NSFileManager defaultManager] fileExistsAtPath:filePath] ? [NSURL fileURLWithPath:filePath] : nil;
}

#pragma mark - Private methods

- (NSString *)_rxr_cachedRouteFilePathForRemoteURL:(NSURL *)url
{
  NSString *md5 = [[url.absoluteString dataUsingEncoding:NSUTF8StringEncoding] md5];
  NSString *filename = [self.cachePath stringByAppendingPathComponent:md5];
  return [filename stringByAppendingPathExtension:url.pathExtension];
}

- (NSString *)_rxr_resourceRouteFilePathForRemoteURL:(NSURL *)url
{
  NSString *filename = nil;
  NSArray *pathComps = url.pathComponents;
  if (pathComps.count > 2) { // 取后两位作为文件路径
    filename = [[pathComps subarrayWithRange:NSMakeRange(pathComps.count - 2, 2)] componentsJoinedByString:@"/"];
  } else {
    filename = url.path;
  }
  return [self.resourcePath stringByAppendingPathComponent:filename];
}

@end
