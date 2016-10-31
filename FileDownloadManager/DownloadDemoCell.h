//
//  DownloadDemoCell.h
//  FileDownloadTool
//
//  Created by MrXia on 15/11/23.
//  Copyright © 2015年 MrXia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DownloadDemoObject.h"

@interface DownloadDemoCell : UITableViewCell

@property (strong, nonatomic) DownloadDemoObject *downloadObject;

- (void)displayCellFromDownloadObject:(DownloadDemoObject *)downloadObject;

@end

