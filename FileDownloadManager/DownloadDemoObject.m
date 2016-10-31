//
//  DownloadDemoObject.m
//  FileDownloadTool
//
//  Created by MrXia on 16/04/03.
//  Copyright © 2016年 MrXia. All rights reserved.
//

#import "DownloadDemoObject.h"

@implementation DownloadDemoObject

- (id)initWithFileDemoModel:(FileDemoModel *)fileModel
{
    if(self = [super init]){
        self.fileId = fileModel.fileId;
        self.fileUrl = fileModel.fileUrl;
        self.fileName = fileModel.fileName;
        self.downloadSpeed = @"";
        self.downloadSize = @"0MB";
        self.totalSize = @"0MB";
        self.totalLength = 0.0;
        self.progress = 0.0;
        self.downloadState = FileDownloadStateWaiting;
    }
    return self;
}

@end
