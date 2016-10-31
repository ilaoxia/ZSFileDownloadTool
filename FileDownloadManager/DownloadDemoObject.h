//
//  DownloadDemoObject.h
//  FileDownloadTool
//
//  Created by MrXia on 16/04/03.
//  Copyright © 2016年 MrXia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileDemoModel.h"
#import "SCSessionDownloadManager.h"

/*
 根据从网络获取的数据model类创建下载model类
 */

@interface DownloadDemoObject : NSObject

@property (copy, nonatomic) NSString *fileId;
@property (copy, nonatomic) NSString *fileUrl;
@property (copy, nonatomic) NSString *fileName;
@property (copy, nonatomic) NSString *totalSize;
@property (copy, nonatomic) NSString *downloadSize;
@property (copy, nonatomic) NSString *downloadSpeed;
@property (copy, nonatomic) NSString *directoryPath;
@property (assign, nonatomic) float progress;
@property (assign, nonatomic) uint64_t totalLength;
@property (assign, nonatomic) FileDownloadState downloadState;

- (id)initWithFileDemoModel:(FileDemoModel *)fileModel;

@end
