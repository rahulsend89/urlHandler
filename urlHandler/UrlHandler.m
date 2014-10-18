//
//  UrlHandler.m
//  urlHandler
//
//  Created by Rahul Malik on 12/10/14.
//  Copyright (c) 2014 Rahul Malik. All rights reserved.
//

#import "UrlHandler.h"
#define REQUESTTIMEOUT 10.0
@interface UrlHandler()
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSOutputStream *downloadStream;
@property (nonatomic, strong) NSString *mainfilename;
@property (getter = isDownloading) BOOL downloading;
@property long long expectedContentLength;
@property long long progressContentLength;
@property (nonatomic, strong) NSError *error;
@end

@implementation UrlHandler
-(BOOL)checkIfFileURL{
    return FALSE;
}
+ (UrlHandler*)sharedInstance{
    static id sharedInstance = nil;
    if (sharedInstance == nil){
        sharedInstance = [[UrlHandler alloc] init];
    }
    return sharedInstance;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        _currentVal = 0;
    }
    return self;
}
-(void)isNetWorking : (void(^)(BOOL val))callBack{
    Reachability *reachability = [Reachability reachabilityWithHostname:@"www.google.com"];
    _reachableBlock = callBack;
    reachability.reachableBlock = ^(Reachability *reachable){
        _reachableBlock(TRUE);
    };
    reachability.unreachableBlock = ^(Reachability *reachable){
        _reachableBlock(FALSE);
    };
    [reachability startNotifier];
}
-(void)initCache{
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024
                                                         diskCapacity:20 * 1024 * 1024
                                                             diskPath:nil];
    [NSURLCache setSharedURLCache:URLCache];
}
-(NSString*)pathValueWithName: (NSString*) fileName :(NSString*) pathName{
    NSString *documentsDirectory = @"";
    if ([pathName isEqualToString:@"doc"]) {
        documentsDirectory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", fileName]];
    }else if([pathName isEqualToString:@"temp"]){
        documentsDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", fileName]];
    }
    return documentsDirectory;
}
-(void)downloadListOfListWithArray:(NSArray*)fileList
                     progressBlock:(void (^)(float pre,int current))progress
                   completionBlock:(void (^)(NSError *error, id returnObject,int currentObj))handler
{
    if (!fileList.count) {
        return;
    }
    _multiCompletionHandler = handler;
    _multiprogressHandler = progress;
    NSURL *tempURL;
    NSString* filename;
    NSString *myURL;
    myURL = [fileList objectAtIndex:0];
    tempURL = [NSURL URLWithString:myURL];
    filename = [tempURL lastPathComponent];
    [[UrlHandler sharedInstance] downloadFileWithURL:myURL withName:filename progressBlock:^(float pre) {
        _multiprogressHandler(pre,_currentVal);
    } completionBlock:^(NSError *error, id returnObject) {
        _multiCompletionHandler(error,returnObject,_currentVal);
        _currentVal++;
        NSMutableArray *array = [NSMutableArray arrayWithArray:fileList];
        [array removeObjectAtIndex:0];        
        [self downloadListOfListWithArray:array progressBlock:_multiprogressHandler completionBlock:_multiCompletionHandler];
    }];
}

-(void)downloadFileWithURL:(NSString*)myURL
                  withName:(NSString*)fileName
             progressBlock:(void (^)(float pre))progress
           completionBlock:(void (^)(NSError *error, id returnObject))handler
{
    _completionHandler = handler;
    _progressHandler = progress;
    [[UrlHandler sharedInstance] isNetWorking:^(BOOL val) {
        if(val){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                self.downloading = YES;
                self.expectedContentLength = -1;
                self.progressContentLength = 0;
                NSString *filePath = [self pathValueWithName:fileName:@"doc"];
                self.mainfilename = filePath;
                self.downloadStream = [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:myURL]
                                                         cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                     timeoutInterval:REQUESTTIMEOUT];
                if (!request) {
                    self.error = [NSError errorWithDomain:[NSBundle mainBundle].bundleIdentifier
                                                     code:-1
                                                 userInfo:@{@"message": @"undefined URL", @"function": @(__FUNCTION__), @"URL" : myURL}];
                    
                    [self downloadCompleted:NO];
                    return;
                }
                if (!self.downloadStream) {
                    self.error = [NSError errorWithDomain:[NSBundle mainBundle].bundleIdentifier
                                                     code:-1
                                                 userInfo:@{@"message": @"undefined NSOutputStream", @"function" : @(__FUNCTION__), @"path" : filePath}];
                    
                    [self downloadCompleted:NO];
                    return;
                }
                [self.downloadStream open];
                
                self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
                [self.connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
                [self.connection start];
                
                if (!self.connection) {
                    self.error = [NSError errorWithDomain:[NSBundle mainBundle].bundleIdentifier
                                                     code:-1
                                                 userInfo:@{@"message": @"undefined NSURLConnection", @"function" : @(__FUNCTION__), @"NSURLRequest" : request}];
                    
                    [self downloadCompleted:NO];
                }
                
            });
        }else{
            NSLog(@"net is not reachable");
        }
    }];
}
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        if (statusCode == 200) {
            self.expectedContentLength = [response expectedContentLength];
        } else if (statusCode >= 400) {
            self.error = [NSError errorWithDomain:[NSBundle mainBundle].bundleIdentifier
                                             code:statusCode
                                         userInfo:@{
                                                    @"message" : @"bad HTTP response status code",
                                                    @"function": @(__FUNCTION__),
                                                    @"NSHTTPURLResponse" : response
                                                    }];
            [self downloadCompleted:NO];
        }
    } else {
        self.expectedContentLength = -1;
    }
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSInteger       dataLength = [data length];
    const uint8_t * dataBytes  = [data bytes];
    NSInteger       bytesWritten;
    NSInteger       bytesWrittenSoFar;
    
    bytesWrittenSoFar = 0;
    do {
        bytesWritten = [self.downloadStream write:&dataBytes[bytesWrittenSoFar] maxLength:dataLength - bytesWrittenSoFar];
        assert(bytesWritten != 0);
        if (bytesWritten == -1) {
            [self downloadCompleted:NO];
            break;
        } else {
            bytesWrittenSoFar += bytesWritten;
        }
    } while (bytesWrittenSoFar != dataLength);
    
    self.progressContentLength += dataLength;
    _progressHandler((float) self.progressContentLength / (float) self.expectedContentLength);
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    _completionHandler(nil,self.mainfilename);
}
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    _completionHandler(error,@"downloadingError");
}

-(void)downloadCompleted:(BOOL)val{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if (self.connection != nil) {
        if (!val) {
            [self.connection cancel];
        }
        self.connection = nil;
    }
    if (self.downloadStream != nil) {
        [self.downloadStream close];
        self.downloadStream = nil;
    }
    self.downloading = NO;
    if (val) {
        if ([fileManager fileExistsAtPath:self.mainfilename]) {
            [fileManager removeItemAtPath:self.mainfilename error:&error];
            if (error) {
                self.error = error;
                _completionHandler(error,@"removeItemAtPath _ downloadFailed");
                return;
            }
        }
        _completionHandler(error,self.mainfilename);
    }else
    {
        if (self.mainfilename)
            if ([fileManager fileExistsAtPath:self.mainfilename])
                [fileManager removeItemAtPath:self.mainfilename error:&error];
        
        _completionHandler(error,@"downloadFailed");
    }
}
-(void)basicURL: (NSString*) myURL : (void (^)(NSError *error, id returnObject))handler{
    _completionHandler = handler;
    [[UrlHandler sharedInstance] isNetWorking:^(BOOL val) {
        if(val){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:myURL]
                                                         cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                     timeoutInterval:REQUESTTIMEOUT];
                NSCachedURLResponse* cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
                if(cachedResponse!=nil){
                    NSError * error = nil;
                    NSString *string = [[NSString alloc] initWithData:[cachedResponse data] encoding:NSUTF8StringEncoding];
                    _completionHandler(error,string);
                }else{
                    NSError * error = nil;
                    NSURLResponse *response = nil;
                    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                                         returningResponse:&response
                                                                     error:&error];
                    if (error == nil)
                    {
                        NSCachedURLResponse *_cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data];
                        [[NSURLCache sharedURLCache] storeCachedResponse:_cachedResponse forRequest:(NSURLRequest *)request];
                        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        _completionHandler(error,string);
                    }else{
                        _completionHandler(error,@"notReachable");
                    }
                }
            });
        }else{
            NSLog(@"net is not reachable");
        }
    }];
    
}
-(void)testMyCode{
    //_completionHandler(ns);
}
@end
