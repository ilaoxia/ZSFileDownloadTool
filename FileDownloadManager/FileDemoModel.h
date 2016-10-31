//
//  FileDemoModel.h
//  FileDownloadTool
//
//  Created by MrXia on 15/11/23.
//  Copyright © 2015年 MrXia. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 模拟从网络获取的数据model类
 */

@interface FileDemoModel : NSObject

@property (copy, nonatomic) NSString *fileId;
@property (copy, nonatomic) NSString *fileName;
@property (copy, nonatomic) NSString *fileUrl;


@end
