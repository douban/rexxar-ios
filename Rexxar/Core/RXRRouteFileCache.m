//
//  RXRRouteFileCache.m
//  Rexxar
//
//  Created by GUO Lin on 5/11/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

#import "RXRRouteFileCache.h"
#import "RXRConfig.h"

#import "RXRLogger.h"
#import "NSData+RXRDigest.h"
#import "RXRLogger.h"
#import "RXRConfig+Rexxar.h"
#import "RXRRouteManager.h"

static NSString * const RoutesMapFile = @"routes.json";

// Resource URLs identify immutable content. Only this class writes cache files.
@interface RXRRouteFileCache ()
@property (nonatomic, strong) NSCache<NSString *, NSNumber *> *validatedFiles;
@property (nonatomic, weak) id<RXRDataValidator> validationDataValidator;
@end

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
    [RXRConfig rxr_logWithType:RXRLogTypeFailedToCreateCacheDirectoryError error:error requestURL:nil localFilePath:_cachePath userInfo:nil];
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
  @synchronized (self) {
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager removeItemAtPath:self.cachePath error:nil];
    [manager createDirectoryAtPath:self.cachePath withIntermediateDirectories:YES attributes:@{} error:NULL];
    [_validatedFiles removeAllObjects];
  }
}

- (NSUInteger)cacheFileSize
{
  return [self _rxr_fileSizeAtPath:self.cachePath];
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

- (NSData *)cacheRoutesMapFile
{
  NSString *filePath = [self.cachePath stringByAppendingPathComponent:RoutesMapFile];
  if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    return [NSData dataWithContentsOfFile:filePath];
  }

  return nil;
}

- (NSData *)resourceRoutesMapFile
{
  NSString *filePath = [self.resourcePath stringByAppendingPathComponent:RoutesMapFile];
  if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    return [NSData dataWithContentsOfFile:filePath];
  }

  return nil;
}

- (void)saveRouteFileData:(NSData *)data withRemoteURL:(NSURL *)url
{
  if (data) {
    [self storeRouteFileData:data withRemoteURL:url];
  } else {
    @synchronized (self) {
      NSString *path = [self _rxr_cachedRouteFilePathForRemoteURL:url];
      [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
      [_validatedFiles removeObjectForKey:path];
    }
  }
}

- (RXRRouteFileStoreResult)storeRouteFileData:(NSData *)data withRemoteURL:(NSURL *)url
{
  @synchronized (self) {
    NSCache *validatedFiles = self.validatedFiles;
    if (![self validateRouteFileData:data withRemoteURL:url]) {
      return RXRRouteFileStoreResultInvalidData;
    }
    NSString *path = [self _rxr_cachedRouteFilePathForRemoteURL:url];
    NSError *error = nil;
    if (![data writeToFile:path options:NSDataWritingAtomic error:&error]) {
      RXRLogObject *log = [[RXRLogObject alloc] initWithLogDescription:@"rxr_write_resource_file_error" error:error requestURL:url localFilePath:path otherInformation:nil];
      [RXRConfig rxr_logWithLogObject:log];
      return RXRRouteFileStoreResultWriteFailed;
    }
    [validatedFiles setObject:@YES forKey:path];
    return RXRRouteFileStoreResultSaved;
  }
}

- (BOOL)validateRouteFileData:(NSData *)data withRemoteURL:(NSURL *)url
{
  BOOL isHTML = [url.pathExtension.lowercaseString isEqualToString:@"html"];
  BOOL valid = data.length > 0;
  if (valid && isHTML) {
    id<RXRDataValidator> validator = [RXRRouteManager sharedInstance].dataValidator;
    if ([validator respondsToSelector:@selector(validateRemoteHTMLFile:fileData:)]) {
      valid = [validator validateRemoteHTMLFile:url fileData:data];
    }
  }

  if (!valid) {
    if (isHTML) {
      [RXRConfig rxr_logWithType:RXRLogTypeValidatingHTMLFileError error:nil requestURL:url localFilePath:nil userInfo:nil];
    } else {
      RXRLogObject *log = [[RXRLogObject alloc] initWithLogDescription:@"rxr_invalid_resource_file" error:nil requestURL:url localFilePath:nil otherInformation:nil];
      [RXRConfig rxr_logWithLogObject:log];
    }
  }
  return valid;
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
  @synchronized (self) {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *path = [self _rxr_cachedRouteFilePathForRemoteURL:url];
    if ([manager fileExistsAtPath:path]) {
      if ([self _rxr_validateFileAtPath:path remoteURL:url]) {
        return path;
      }
      [manager removeItemAtPath:path error:nil];
    }
    [_validatedFiles removeObjectForKey:path];

    path = [self _rxr_resourceRouteFilePathForRemoteURL:url];
    if ([manager fileExistsAtPath:path] && [self _rxr_validateFileAtPath:path remoteURL:url]) {
      return path;
    }
    return nil;
  }
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

// Accessed under @synchronized(self), together with cache file reads/writes.
- (NSCache<NSString *, NSNumber *> *)validatedFiles
{
  id<RXRDataValidator> validator = [RXRRouteManager sharedInstance].dataValidator;
  if (!_validatedFiles || _validationDataValidator != validator) {
    _validatedFiles = [[NSCache alloc] init];
    _validationDataValidator = validator;
  }
  return _validatedFiles;
}

- (BOOL)_rxr_validateFileAtPath:(NSString *)path remoteURL:(NSURL *)url
{
  NSCache *validatedFiles = self.validatedFiles;
  if ([validatedFiles objectForKey:path]) {
    return YES;
  }
  if (![self validateRouteFileData:[NSData dataWithContentsOfFile:path] withRemoteURL:url]) {
    return NO;
  }
  [validatedFiles setObject:@YES forKey:path];
  return YES;
}

- (NSString *)_rxr_cachedRouteFilePathForRemoteURL:(NSURL *)url
{
  NSString *cacheKey = url.absoluteString;
  if (RXRConfig.URLCacheConverter != nil) {
    cacheKey = [RXRConfig.URLCacheConverter cacheKeyForURL:url];
  }

  NSString *md5 = [[cacheKey dataUsingEncoding:NSUTF8StringEncoding] md5];
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

- (NSUInteger)_rxr_fileSizeAtPath:(NSString *)path
{
  NSFileManager *manager = [NSFileManager defaultManager];
  NSUInteger totalSize = 0;
  NSArray<NSString *> *contents = [manager contentsOfDirectoryAtPath:path error:nil];

  for (NSString *name in contents) {
    NSString *itemPath = [path stringByAppendingPathComponent:name];
    NSDictionary<NSFileAttributeKey, id> *attrs = [manager attributesOfItemAtPath:itemPath error:nil];
    NSFileAttributeType type = [attrs objectForKey:NSFileType];
    if (!type) {
      continue;
    }
    if ([type isEqualToString:NSFileTypeDirectory]) {
      totalSize += [self _rxr_fileSizeAtPath:itemPath];
    } else if ([attrs objectForKey:NSFileSize]) {
      totalSize += [[attrs objectForKey:NSFileSize] unsignedIntegerValue];
    }
  }

  return totalSize;
}

@end
