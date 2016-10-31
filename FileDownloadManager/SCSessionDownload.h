//
//  SCSessionDownload.h
//  FileDownloadTool
//
//  Created by MrXia on 16/04/03.
//  Copyright © 2016年 MrXia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCSessionDownload : NSObject

@property (copy, nonatomic) NSString *fileId;           //文件的唯一标识
@property (copy, nonatomic) NSString *fileUrl;          //文件的网址
@property (copy, nonatomic) NSString *fileName;         //文件的名字
@property (strong, nonatomic) NSString *directoryPath;
@property (nonatomic, strong) NSOutputStream *outPutStream;
@property (nonatomic, assign) NSInteger currentSize;
@property (nonatomic, assign) NSInteger totalSize;

@property (copy, nonatomic, readonly) NSString *downloadSpeed;    //文件的下载速度

- (id)initWithURL:(NSString *)fileUrl directoryPath:(NSString *)directoryPath fileName:(NSString *)fileName;

- (void)startDownloadWithBackgroundSession:(NSURLSession *)session;

- (void)cancelDownloadIfDeleteFile:(BOOL)deleteFile;

- (void)setBytesWritten:(uint64_t)bytesWritten iFCalculateSpeed:(BOOL)ifCalculate;

- (BOOL)isCompletion;

@end








