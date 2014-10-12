//
//  UrlHandler.m
//  urlHandler
//
//  Created by Rahul Malik on 12/10/14.
//  Copyright (c) 2014 Rahul Malik. All rights reserved.
//

#import "UrlHandler.h"
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
-(void)testURL: (NSString*) myURL : (void (^)(NSError *error, id returnObject))handler{
    _completionHandler = handler;
    [[UrlHandler sharedInstance] isNetWorking:^(BOOL val) {
        if(val){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:myURL]
                                                         cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                     timeoutInterval:3.0];
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
