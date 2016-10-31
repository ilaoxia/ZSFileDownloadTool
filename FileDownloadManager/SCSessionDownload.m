//
//  SCSessionDownload.m
//  FileDownloadTool
//
//  Created by MrXia on 16/04/03.
//  Copyright © 2016年 MrXia. All rights reserved.
//

#import "SCSessionDownload.h"

@interface SCSessionDownload ()

@property (strong, nonatomic) NSURL *downloadURL;
@property (strong, nonatomic) NSURLSessionDataTask *downloadTask;
@property (assign, nonatomic) uint64_t timerReceivedDataLength;

@end

@implementation SCSessionDownload

- (id)initWithURL:(NSString *)fileUrl directoryPath:(NSString *)directoryPath fileName:(NSString *)fileName
{
    if(self = [super init]){
        self.fileUrl = fileUrl;
        self.fileName = fileName;
        self.directoryPath = directoryPath;
        self.downloadURL = [NSURL URLWithString:[fileUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    return self;
}

#pragma mark --- Public Method ---

- (void)startDownloadWithBackgroundSession:(NSURLSession *)session
{
    //确定是否存在已经下载的文件,如存在,继续下载.
    self.currentSize = [self getSize];
        
    //创建缓存目录
    [self createCacheDirectory];
    
    // 创建流
    NSString *fullPath = [self.directoryPath stringByAppendingPathComponent:self.fileName];
    NSOutputStream *stream = [NSOutputStream outputStreamToFileAtPath:fullPath append:YES];
    self.outPutStream = stream;
    
    
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_downloadURL];
    
    //设置请求头信息
    NSString *header = [NSString stringWithFormat:@"bytes=%zd-",self.currentSize];
    [request setValue:header forHTTPHeaderField:@"Range"];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request];
    _downloadTask = dataTask;
    
    [_downloadTask resume];
}

- (void)cancelDownloadIfDeleteFile:(BOOL)deleteFile
{
    if(deleteFile){
        //暂停并删除文件
        [self deleteFile];
        //[DSDownloadTool ]
        
    }else{
        //只暂停
        [self pauseFile];
    }
}

- (void)setBytesWritten:(uint64_t)bytesWritten iFCalculateSpeed:(BOOL)ifCalculate
{
    _timerReceivedDataLength += bytesWritten;
    if(ifCalculate){
        float downloadData = (float)_timerReceivedDataLength/1024.0;
        if(downloadData>=1024.0){
            downloadData /= 1024.0;
            _downloadSpeed = [NSString stringWithFormat:@"%.1fMB/s",downloadData];
        }
        else{
            _downloadSpeed = [NSString stringWithFormat:@"%.1fKB/s",downloadData];
        }
        _timerReceivedDataLength = 0;
    }
}

#pragma mark --- Private Method ---

//文件夹和文件拼接后的路径
- (NSString *)finishFilePath
{
    return [self.directoryPath stringByAppendingPathComponent:self.fileName];
}

/**
 *  判断该文件是否下载完成
 */
- (BOOL)isCompletion
{
    if (self.currentSize == self.totalSize) {
        return YES;
    }
    return NO;
}

- (NSInteger)getSize{
    //0.拼接文件全路径
    NSString *fullPath = [self.directoryPath stringByAppendingPathComponent:self.fileName];
    
    //先把沙盒中的文件大小取出来
    NSDictionary *dict = [[NSFileManager defaultManager]attributesOfItemAtPath:fullPath error:nil];
    NSInteger size = [[dict objectForKey:@"NSFileSize"]integerValue];
    return size;
}

/**
 *  删除该资源
 */
- (void)deleteFile;
{
    if (self.downloadTask) {
        // 取消下载
        [self.downloadTask cancel];
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:self.directoryPath]) {
        // 删除沙盒中的资源
        NSString *fullPath = [self.directoryPath stringByAppendingPathComponent:self.fileName];
        [fileManager removeItemAtPath:fullPath error:nil];
        [self.outPutStream close];
        //删除下载记录
        
    }
}

/**
 *  暂停下载
 */
- (void)pauseFile
{
    [_downloadTask cancel];
}

/**
 *  创建缓存目录文件
 */
- (void)createCacheDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.directoryPath]) {
        [fileManager createDirectoryAtPath:self.directoryPath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

@end














