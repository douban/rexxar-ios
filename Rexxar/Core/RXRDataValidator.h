//
//  RXRDataValidator.h
//  Rexxar
//
//  Created by bigyelow on 06/11/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

#ifndef RXRDataValidator_h
#define RXRDataValidator_h


/**
 可在 `RXRConfig` 中设置 `RXRDataValidator`，`Rexxar` 不提供默认实现。
 目前只提供验证下载的 HTML file 的方法。
 */
@protocol RXRDataValidator<NSObject>

#pragma mark - Downloading HTML files related validation
/**
 验证下载的 `fileData` 是否是合法的。

 @param fileURL 下载文件对应的 remote URL
 @param fileData 下载的文件数据
 @return 是否通过验证
 */
- (BOOL)validateRemoteHTMLFile:(nullable NSURL *)fileURL fileData:(nullable NSData *)fileData;

/**
 如果验证失败，是否停止继续下载其他文件。

 @return 是否停止继续下载其他文件
 */
- (BOOL)stopDownloadingIfValidationFailed;

@end


#endif /* RXRDataValidator_h */
