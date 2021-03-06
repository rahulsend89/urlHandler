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
@property (strong, nonatomic) NSInputStream *uploadStream;
@property (nonatomic, strong) NSString *mainfilename;
@property (getter = isDownloading) BOOL downloading;
@property (getter = isUploading) BOOL uploading;
@property long long expectedContentLength;
@property long long progressContentLength;
@property (nonatomic, strong) NSError *error;
@property(strong, nonatomic) NSMutableDictionary *dictionary;
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
                NSString *key = [NSString stringWithFormat:@"%p", self.connection];
                self.dictionary[key] = [NSMutableData data];
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
-(NSMutableDictionary *)dictionary{
    if (_dictionary == nil){
        _dictionary = [NSMutableDictionary dictionary];
    }
    return _dictionary;
}
- (NSMutableData *)dataForConnection:(NSURLConnection *)connection {

    NSString *key = [NSString stringWithFormat:@"%p", connection];
    return self.dictionary[key];
}
- (void)removeConnection:(NSURLConnection *)connection {

    NSString *key = [NSString stringWithFormat:@"%p", connection];
    return [self.dictionary removeObjectForKey:key];
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
    NSMutableData *responseData = [self dataForConnection:connection];
    [responseData appendData:data];
    if (!self.downloading) {
        return;
    }
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
    if (self.mainfilename) {
        _completionHandler(nil,self.mainfilename);
    }else{
        NSError *error;
        NSMutableData *responseData = [self dataForConnection:connection];
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:responseData options: 0 error: &error];
        _completionHandler(nil,result);
        [self removeConnection:connection];
    }
}
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    _completionHandler(error,@"downloadingError");
}
- (void)connection:(NSURLConnection *)connection   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite{
    _progressHandler((float) totalBytesWritten / (float) totalBytesExpectedToWrite);
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
        
        _completionHandler(error,@"ConnectionFailed");
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
-(void)multipleFormUrl:(NSString*) myURL :(NSString*)urlMethod
        postDictionary:(NSDictionary*)dictionary
        progressBlock :(void (^)(float pre))progress
       completionBlock:(void (^)(NSError *error, id returnObject))handler{
    _completionHandler = handler;
    _progressHandler = progress;
    [[UrlHandler sharedInstance] isNetWorking:^(BOOL val) {
        if(val){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:myURL]
                                                                       cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                                   timeoutInterval:REQUESTTIMEOUT];
                [request setHTTPMethod:urlMethod];
                NSDate *dt = [[NSDate alloc] initWithTimeIntervalSinceNow:0];
                int timestamp = [dt timeIntervalSince1970];
                NSString *charset = (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
                NSString *formRequestBodyBoundary = [NSString stringWithFormat:@"BOUNDARY-%d-%@", timestamp, [[NSProcessInfo processInfo] globallyUniqueString]];
                [request addValue:[NSString stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@",charset, formRequestBodyBoundary] forHTTPHeaderField:@"Content-Type"];
                NSMutableData *formRequestBody = [NSMutableData data];
                [formRequestBody appendData:[[NSString stringWithFormat:@"--%@\r\n",formRequestBodyBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
                NSMutableArray *HTTPRequestBodyParts = [NSMutableArray array];
                NSData *filePath;
                for (NSString*key in dictionary) {
                    if ([key isEqualToString:@"file"]) {
                        NSDictionary *fileInfo = [dictionary objectForKey:key];
                        NSMutableData *someData = [[NSMutableData alloc] init];
                        [someData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", [fileInfo objectForKey:@"key"],[fileInfo objectForKey:@"fileName"]] dataUsingEncoding:NSUTF8StringEncoding]];
                        [someData appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", [fileInfo objectForKey:@"contentType"]] dataUsingEncoding:NSUTF8StringEncoding]];
                        filePath = [fileInfo objectForKey:@"data"];
                        [someData appendData:filePath];
                        [HTTPRequestBodyParts addObject:someData];
                    }else{
                        NSMutableData *someData = [[NSMutableData alloc] init];
                        [someData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
                        [someData appendData:[[NSString stringWithFormat:@"%@", [dictionary objectForKey:key]] dataUsingEncoding:NSUTF8StringEncoding]];
                        [HTTPRequestBodyParts addObject:someData];
                    }
                }
                
                NSMutableData *resultingData = [NSMutableData data];
                NSUInteger count = [HTTPRequestBodyParts count];
                [HTTPRequestBodyParts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    [resultingData appendData:obj];
                    if (idx != count - 1) {
                        [resultingData appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", formRequestBodyBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
                    }
                }];
                [formRequestBody appendData:resultingData];
                [formRequestBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", formRequestBodyBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
                [request setHTTPBody:formRequestBody];
                self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
                NSString *key = [NSString stringWithFormat:@"%p", self.connection];
                self.dictionary[key] = [NSMutableData data];
                [self.connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
                [self.connection start];
                if (!self.connection) {
                    self.error = [NSError errorWithDomain:[NSBundle mainBundle].bundleIdentifier
                                                     code:-1
                                                 userInfo:@{@"message": @"undefined NSURLConnection", @"function" : @(__FUNCTION__), @"NSURLRequest" : request}];
                    
                }
            });
        }
    }];
}
-(void)basicFormURL: (NSString*) myURL : (NSString*)urlMethod :(NSDictionary*)dictionary : (void (^)(NSError *error, id returnObject))handler{
    _completionHandler = handler;
    [[UrlHandler sharedInstance] isNetWorking:^(BOOL val) {
        if(val){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:myURL]
                                                                       cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                                   timeoutInterval:REQUESTTIMEOUT];
                [request setHTTPMethod:urlMethod];
                NSDate *dt = [[NSDate alloc] initWithTimeIntervalSinceNow:0];
                int timestamp = [dt timeIntervalSince1970];
                NSString *charset = (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
                NSString *formRequestBodyBoundary = [NSString stringWithFormat:@"BOUNDARY-%d-%@", timestamp, [[NSProcessInfo processInfo] globallyUniqueString]];
                [request addValue:[NSString stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@",charset, formRequestBodyBoundary] forHTTPHeaderField:@"Content-Type"];
                NSMutableData *formRequestBody = [NSMutableData data];
                [formRequestBody appendData:[[NSString stringWithFormat:@"--%@\r\n",formRequestBodyBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
                NSEnumerator *enumerator = [dictionary keyEnumerator];
                NSString *key;
                NSMutableArray *HTTPRequestBodyParts = [NSMutableArray array];
                while ((key = [enumerator nextObject])) {
                    NSMutableData *someData = [[NSMutableData alloc] init];
                    [someData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
                    [someData appendData:[[NSString stringWithFormat:@"%@", [dictionary objectForKey:key]] dataUsingEncoding:NSUTF8StringEncoding]];
                    [HTTPRequestBodyParts addObject:someData];
                }
                NSMutableData *resultingData = [NSMutableData data];
                NSUInteger count = [HTTPRequestBodyParts count];
                [HTTPRequestBodyParts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    [resultingData appendData:obj];
                    if (idx != count - 1) {
                        [resultingData appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", formRequestBodyBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
                    }
                }];
                [formRequestBody appendData:resultingData];
                [formRequestBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", formRequestBodyBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
                [request setHTTPBody:formRequestBody];
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
