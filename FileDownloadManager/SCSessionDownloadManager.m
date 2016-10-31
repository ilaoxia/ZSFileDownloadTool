//
//  SCSessionDownloadManager.m
//  FileDownloadTool
//
//  Created by MrXia on 16/4/3.
//  Copyright © 2016年 MrXia. All rights reserved.
//

#import "SCSessionDownloadManager.h"

const NSTimeInterval sDefaultTimeOut = 60.0;
const NSTimeInterval sCalculateSpeedTime = 1;

#define  DefaultConDownloadCount    1         //默认同时下载数，可修改

#define  RESPONSE_TO_WAITING_METHOD 0
#define  RESPONSE_TO_SUSPEND_METHOD 0

@interface SCSessionDownloadManager ()<NSURLSessionDataDelegate>

@property (strong, nonatomic) NSMutableArray *waitingArray;           //排队的
@property (strong, nonatomic) NSMutableArray *suspendingArray;        //暂停的
@property (strong, nonatomic) NSMutableArray *downloadingArray;       //下载的
@property (strong, nonatomic) NSMutableArray *failureArray;

@property (assign, nonatomic, readonly) NSInteger currentDownloadCount;  //当前下载中总数
@property (assign, nonatomic, readonly) NSInteger currentWaitingCount;   //当前等待中总数

@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) BOOL isReadyToCalculate;

@end

@implementation SCSessionDownloadManager

+ (instancetype)sharedSessionDownloadManager
{
    static dispatch_once_t onceToken;
    static SCSessionDownloadManager *sessionDownloadManager = nil;
    dispatch_once(&onceToken, ^{
        sessionDownloadManager = [[SCSessionDownloadManager alloc] init];
    });
    return sessionDownloadManager;
}

- (instancetype)init
{
    if(self = [super init]){
        _failureArray = [NSMutableArray array];
        _waitingArray = [NSMutableArray array];
        _suspendingArray = [NSMutableArray array];
        _downloadingArray = [NSMutableArray array];
        _maxConDownloadCount = DefaultConDownloadCount;
    }
    return self;
}

#pragma mark --- Publick Download ---

//此方法只是最初添加到下载队列时使用，只调用一次
- (void)addDownloadWithFileId:(NSString *)fileId fileUrl:(NSString *)url directoryPath:(NSString *)directoryPath fileName:(NSString *)fileName
{
    SCSessionDownload *sessionDownload = [[SCSessionDownload alloc] initWithURL:url directoryPath:directoryPath fileName:fileName];
    sessionDownload.fileId = fileId;
    sessionDownload.fileUrl = url;
    sessionDownload.fileName = fileName;
    sessionDownload.directoryPath = directoryPath;
    [self startDownloadIfNecessaryWithSessionDownload:sessionDownload];
}

- (void)startDownloadWithFileId:(NSString *)fileId
{
    if(self.currentDownloadCount==0){
        return;
    }
    //暂停
    if(RESPONSE_TO_WAITING_METHOD){
        for(SCSessionDownload *download in _waitingArray){
            if([download.fileId isEqualToString:fileId]){
                [_suspendingArray addObject:download];
                [_waitingArray removeObject:download];
                break;
            }
        }
        return;
    }
    //立即下载
    SCSessionDownload *firstDownload = [_downloadingArray firstObject];
    [firstDownload cancelDownloadIfDeleteFile:NO];
    [_downloadingArray removeObject:firstDownload];
    [_waitingArray addObject:firstDownload];
    [self addToDownloadInWaitingArrayWithFileId:fileId];
}

- (void)suspendDownloadWithFileId:(NSString *)fileId
{
    for(SCSessionDownload *download in _downloadingArray){
        if([download.fileId isEqualToString:fileId]){
            [download cancelDownloadIfDeleteFile:NO];
            [_suspendingArray addObject:download];
            [_downloadingArray removeObject:download];
            break;
        }
    }
    [self autoStartDownloadInWaitingArray];
}

- (void)recoverDownloadWithFileId:(NSString *)fileId
{
    //添加到队列
    if(RESPONSE_TO_SUSPEND_METHOD){
        [self addToDownloadInSuspendArrayWithFileId:fileId];
        return;
    }
    //立即下载
    if(![self canAddDownloadWithoutCancel]){
        SCSessionDownload *firstDownload = [_downloadingArray firstObject];
        [firstDownload cancelDownloadIfDeleteFile:NO];
        [_downloadingArray removeObject:firstDownload];
        [_waitingArray addObject:firstDownload];
    }
    [self addToDownloadInSuspendArrayWithFileId:fileId];
}

- (void)restartDownloadWithFileId:(NSString *)fileId
{
    [self addToDownloadInFailureArrayWithFileId:fileId];
}

- (void)cancelDownloadWithFileId:(NSString *)fileId
{
    for(SCSessionDownload *download in _downloadingArray){
        if([download.fileId isEqualToString:fileId]){
            [download cancelDownloadIfDeleteFile:YES];
            [_downloadingArray removeObject:download];
            [self autoStartDownloadInWaitingArray];
            return;
        }
    }
    for(SCSessionDownload *download in _suspendingArray){
        if([download.fileId isEqualToString:fileId]){
            [_suspendingArray removeObject:download];
            return;
        }
    }
    for(SCSessionDownload *download in _waitingArray){
        if([download.fileId isEqualToString:fileId]){
            [_waitingArray removeObject:download];
            return;
        }
    }
    for(SCSessionDownload *download in _failureArray){
        if([download.fileId isEqualToString:fileId]){
            [_failureArray removeObject:download];
            return;
        }
    }
}

- (void)suspendAllFilesDownload
{
    for(SCSessionDownload *download in _downloadingArray){
        [download cancelDownloadIfDeleteFile:NO];
    }
    [_suspendingArray addObjectsFromArray:_downloadingArray];
    [_suspendingArray addObjectsFromArray:_waitingArray];
    [_downloadingArray removeAllObjects];
    [_waitingArray removeAllObjects];
}

- (void)recoverAllFilesDownload
{
    for(SCSessionDownload *download in _suspendingArray){
        [self startDownloadIfNecessaryWithSessionDownload:download];
    }
    for(SCSessionDownload *download in _failureArray){
        [self startDownloadIfNecessaryWithSessionDownload:download];
    }
    [_suspendingArray removeAllObjects];
    [_failureArray removeAllObjects];
}

- (void)cancelAllFilesDownload
{
    for(SCSessionDownload *download in _downloadingArray){
        [download cancelDownloadIfDeleteFile:YES];
    }
    [_downloadingArray removeAllObjects];
    [_suspendingArray removeAllObjects];
    [_waitingArray removeAllObjects];
    [_failureArray removeAllObjects];
}

- (FileDownloadState)getFileDownloadStateWithFileId:(NSString *)fileId
{
    for(SCSessionDownload *sessionDownload in _suspendingArray){
        if([sessionDownload.fileId isEqualToString:fileId]){
            return FileDownloadStateSuspending;
        }
    }
    for(SCSessionDownload *sessionDownload in _downloadingArray){
        if([sessionDownload.fileId isEqualToString:fileId]){
            return FileDownloadStateDownloading;
        }
    }
    for(SCSessionDownload *sessionDownload in _failureArray){
        if([sessionDownload.fileId isEqualToString:fileId]){
            return FileDownloadStateFail;
        }
    }
    return FileDownloadStateWaiting;
}

- (NSArray *)getDowningArray{
    return _downloadingArray;
}

#pragma mark --- Private Method ---

- (NSURLSession *)backgroundSession
{
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfiguration.allowsCellularAccess = NO;                   //是否允许蜂窝网络访问（2G/3G/4G）
        sessionConfiguration.timeoutIntervalForRequest = sDefaultTimeOut;              //请求超时时间；默认为60秒
        sessionConfiguration.HTTPMaximumConnectionsPerHost = _maxConDownloadCount;           //限制每次最多连接数；在 iOS 中默认值为4
        sessionConfiguration.discretionary = YES;                         //是否自动选择最佳网络，仅「后台会话」有效
        
        session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
        
    });
    return session;
}

- (BOOL)canAddDownloadWithoutCancel
{
    return self.maxConDownloadCount>self.currentDownloadCount;
}

- (void)addToDownloadInSuspendArrayWithFileId:(NSString *)fileId
{
    for(SCSessionDownload *download in _suspendingArray){
        if([download.fileId isEqualToString:fileId]){
            [self startDownloadImmediatelyWithSessionDownload:download];
            [_suspendingArray removeObject:download];
            break;
        }
    }
}

- (void)addToDownloadInWaitingArrayWithFileId:(NSString *)fileId
{
    for(SCSessionDownload *download in _waitingArray){
        if([download.fileId isEqualToString:fileId]){
            [self startDownloadImmediatelyWithSessionDownload:download];
            [_waitingArray removeObject:download];
            break;
        }
    }
}

- (void)addToDownloadInFailureArrayWithFileId:(NSString *)fileId
{
    for(SCSessionDownload *download in _failureArray){
        if([download.fileId isEqualToString:fileId]){
            [self startDownloadIfNecessaryWithSessionDownload:download];
            [_failureArray removeObject:download];
            break;
        }
    }
}

- (void)startDownloadIfNecessaryWithSessionDownload:(SCSessionDownload *)sessionDownload
{
    if([self canAddDownloadWithoutCancel]){
        [self startDownloadImmediatelyWithSessionDownload:sessionDownload];
    }
    else{
        [_waitingArray addObject:sessionDownload];
    }
}

- (void)startDownloadImmediatelyWithSessionDownload:(SCSessionDownload *)sessionDownload
{
    [_downloadingArray addObject:sessionDownload];
    [sessionDownload startDownloadWithBackgroundSession:[self backgroundSession]];
    [self startCalculateDownloadSpeed];
}

- (void)autoStartDownloadInWaitingArray
{
    SCSessionDownload *firstDownload = nil;
    if(self.currentWaitingCount>0){
        firstDownload = [self.waitingArray firstObject];
        [self startDownloadImmediatelyWithSessionDownload:firstDownload];
        [_waitingArray removeObject:firstDownload];
    }
}

- (void)startCalculateDownloadSpeed
{
    _timer = [NSTimer scheduledTimerWithTimeInterval:sCalculateSpeedTime target:self selector:@selector(CalculateDownloadSpeed) userInfo:nil repeats:YES];
}

- (void)stopCalculateDownloadSpeed
{
    if(_timer){
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)CalculateDownloadSpeed
{
    _isReadyToCalculate = YES;
}

#pragma mark --- Set & Get ---

- (NSInteger)currentDownloadCount
{
    return [_downloadingArray count];
}

- (NSInteger)currentWaitingCount
{
    return [_waitingArray count];
}


#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    
    //此处注意,不设置为allow,其它delegate methods将不被执行
    completionHandler(NSURLSessionResponseAllow);
    
    NSString *fileUrl = dataTask.originalRequest.URL.absoluteString;
    __block SCSessionDownload *targetDownload = nil;
    [_downloadingArray enumerateObjectsUsingBlock:^(SCSessionDownload *obj, NSUInteger idx, BOOL * stop) {
        if([obj.fileUrl isEqualToString:fileUrl]){
            targetDownload = obj;
            *stop = YES;
        }
    }];
    
    targetDownload.totalSize = response.expectedContentLength + targetDownload.currentSize;
    
    [targetDownload.outPutStream open];
    
//    //拼接文件全路径
//    NSString *fullPath = [targetDownload.directoryPath stringByAppendingPathComponent:targetDownload.fileName];
//    
//    //1.创建输出流
//    NSOutputStream *outPutStream = [NSOutputStream outputStreamToFileAtPath:fullPath append:YES];
//    [outPutStream open];
//    targetDownload.outPutStream = outPutStream;
}


//2.当接受到服务器返回的数据的时候调用,会调用多次
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    
    NSString *fileUrl = dataTask.originalRequest.URL.absoluteString;
    __block SCSessionDownload *targetDownload = nil;
    [_downloadingArray enumerateObjectsUsingBlock:^(SCSessionDownload *obj, NSUInteger idx, BOOL * stop) {
        if([obj.fileUrl isEqualToString:fileUrl]){
            targetDownload = obj;
            *stop = YES;
        }
    }];
    targetDownload.currentSize += data.length;
    [targetDownload setBytesWritten:data.length iFCalculateSpeed:_isReadyToCalculate];
    _isReadyToCalculate = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        if(_delegate && [_delegate respondsToSelector:@selector(sessionDownloadManagerUpdateProgress:didWriteData:fileSize:downloadSpeed:)]){
            [_delegate sessionDownloadManagerUpdateProgress:targetDownload didWriteData:targetDownload.currentSize fileSize:targetDownload.totalSize downloadSpeed:targetDownload.downloadSpeed];
        }
    });
    
    [targetDownload.outPutStream write:data.bytes maxLength:data.length];
    
}


//3.当整个请求结束的时候调用,error有值的话,那么说明请求失败
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    
    [self stopCalculateDownloadSpeed];
    NSString *fileUrl = task.originalRequest.URL.absoluteString;
    __block SCSessionDownload *targetDownload = nil;
    [_downloadingArray enumerateObjectsUsingBlock:^(SCSessionDownload *obj, NSUInteger idx, BOOL * stop) {
        if([obj.fileUrl isEqualToString:fileUrl]){
            targetDownload = obj;
            *stop = YES;
        }
    }];
    
    if (!targetDownload) {
        return;
    }
    
    [targetDownload.outPutStream close];
    targetDownload.outPutStream = nil;
    
    
    if(error && error.code!=-999){
        
        [_downloadingArray removeObject:targetDownload];
        [_failureArray addObject:targetDownload];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(_delegate && [_delegate respondsToSelector:@selector(sessionDownloadManagerFinishDownload:success:error:)]){
                [_delegate sessionDownloadManagerFinishDownload:targetDownload success:NO error:error];
            }
        });
    }else if ([targetDownload isCompletion]){
        [_downloadingArray removeObject:targetDownload];
        [self autoStartDownloadInWaitingArray];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(_delegate && [_delegate respondsToSelector:@selector(sessionDownloadManagerFinishDownload:success:error:)]){
                [_delegate sessionDownloadManagerFinishDownload:targetDownload success:YES error:nil];
            }
        });
    
    }
    
}



@end













