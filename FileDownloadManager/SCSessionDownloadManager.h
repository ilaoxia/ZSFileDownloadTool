//
//  SCSessionDownloadManager.h
//  FileDownloadTool
//
//  Created by MrXia on 16/04/03.
//  Copyright © 2016年 MrXia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCSessionDownload.h"

typedef NS_ENUM(NSInteger, FileDownloadState){
    FileDownloadStateWaiting = 0,
    FileDownloadStateDownloading = 1,
    FileDownloadStateSuspending = 2,
    FileDownloadStateFail = 3,
    FileDownloadStateFinish = 4,
};



@protocol SCSessionDownloadManagerDelegate <NSObject>

- (void)sessionDownloadManagerStartDownload:(SCSessionDownload *)download;
- (void)sessionDownloadManagerUpdateProgress:(SCSessionDownload *)download didWriteData:(uint64_t)writeLength fileSize:(uint64_t)totalLength downloadSpeed:(NSString *)downloadSpeed;
- (void)sessionDownloadManagerFinishDownload:(SCSessionDownload *)download success:(BOOL)downloadSuccess error:(NSError *)error;

@end

@interface SCSessionDownloadManager : NSObject

+ (instancetype)sharedSessionDownloadManager;

/*
 注意若想修改同时下载多个视频，需保证下载的文件地址是非重复的
 */
@property (assign, nonatomic) NSInteger maxConDownloadCount;
@property (assign, nonatomic) id<SCSessionDownloadManagerDelegate>delegate;

//添加到下载队列
- (void)addDownloadWithFileId:(NSString *)fileId fileUrl:(NSString *)url directoryPath:(NSString *)directoryPath fileName:(NSString *)fileName;

//点击等待项（－》立即下载／暂停／do nothing）
- (void)startDownloadWithFileId:(NSString *)fileId;

//点击下载项 －》暂停
- (void)suspendDownloadWithFileId:(NSString *)fileId;

//点击暂停项（－》立刻下载／添加到下载队列）
- (void)recoverDownloadWithFileId:(NSString *)fileId;

//点击失败项 －》添加到下载队列
- (void)restartDownloadWithFileId:(NSString *)fileId;

//取消下载，且删除文件，只适用于未下载完成状态，下载完成的直接根据路径删除即可
- (void)cancelDownloadWithFileId:(NSString *)fileId;

//暂停全部：下载的，等待的
- (void)suspendAllFilesDownload;

//恢复全部：暂停的，失败的
- (void)recoverAllFilesDownload;

//取消全部：下载的，等待的，暂停的，失败的
- (void)cancelAllFilesDownload;

//获得状态
- (FileDownloadState)getFileDownloadStateWithFileId:(NSString *)fileId;

//获取当前正在下载的数组
- (NSArray *)getDowningArray;

@end
















