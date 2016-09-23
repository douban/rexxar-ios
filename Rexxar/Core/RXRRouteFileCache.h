//
//  RXRRouteFileCache.h
//  Rexxar
//
//  Created by GUO Lin on 5/11/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 * `RXRRouteCache` 提供对 Route files 的读取。
 * Route files 包括用于渲染 rexxar 页面的静态文件，例如 html, css, js, image。
 * 为何我们会自己实现一个缓存，而不使用 NSURLCache?
 * 因为获取 Route 信息有两个来源，要么从本地缓存（上线后发布，下载的资源会有本地缓存），要么资源文件夹（上线时打入的）。这和 NSURLCache 缓存机制不同。
 * 1. 本地缓存；
 * 2. 资源：应用打包的资源文件中有一份, 这部分资源不会改变。
 *
 * `RXRRouteCache` offer the access method of Route files.
 * Route files include rexxar page 's static file like html, css, js, image.
 * Why we write this cache instead of using NSURLCache?
 * It's because that there are two sources of Route files，local cache (create and save the downloaded resources in cache after app release) or resource file (in the release ipa):
 * 1. local cache: disk cache；
 * 2. resource file: a copy in ipa's resource bundle, this resource will not change.
 */
@interface RXRRouteFileCache : NSObject

/**
 * cachePath, 如果是相对路径的话，则认为其是相对于应用缓存路径。
 */
@property (nonatomic, copy) NSString *cachePath;

/**
 * Rexxar 资源地址, 会在打包应用时，打包进入 ipa。如果是相对路径的话，则认为其是相对于 main bundle 路径。
 */
@property (nonatomic, copy) NSString *resourcePath;

/**
 * 单例方法，获取一个 RXRRouteFileCache 实例。
 *
 * Get RXRRouteFileCache Singleton instance.
 */
+ (RXRRouteFileCache *)sharedInstance;

/**
 * 存储 Route Map File，文件名为 `routes.json`。
 *
 * Save routes map file with file name : `routes.json`.
 */
- (void)saveRoutesMapFile:(NSData *)data;

/**
 * 读取 Route Map File。
 *
 * Read routes map file.
 */
- (nullable NSData *)routesMapFile;


/**
 * 将 `url` 下载下来的资源数据，存入缓存。
 *
 * Save the route file with url.
 */
- (void)saveRouteFileData:(NSData *)data withRemoteURL:(NSURL *)url;

/**
 * 从缓存中读取出 `url` 下载的资源。
 *
 * Read the route file according url.
 */
- (nullable NSData *)routeFileDataForRemoteURL:(NSURL *)url;

/**
 * 获取远程 url 对于的本地 url。先在缓存文件夹中寻找，再在资源文件夹中寻找。如果在缓存文件和资源文件中都找不到对应的本地文件，返回 nil。
 *
 * Get the local url for remote url. Search the local file first from cache file, then from resource file. 
 * If it dose not exist in cache file and resource file, return nil.
 */
- (nullable NSURL *)routeFileURLForRemoteURL:(NSURL *)url;

/**
 * 清理缓存。
 *
 * Clean Cache。
 */
- (void)cleanCache;

@end

NS_ASSUME_NONNULL_END
