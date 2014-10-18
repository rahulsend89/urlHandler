//
//  UrlHandler.h
//  urlHandler
//
//  Created by Rahul Malik on 12/10/14.
//  Copyright (c) 2014 Rahul Malik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"
@interface UrlHandler : NSObject{
    
}
-(BOOL)checkIfFileURL;
-(void)testMyCode;
@property (nonatomic, strong) void(^completionHandler)(NSError *, id responseObject);
@property (nonatomic, strong) void(^multiCompletionHandler)(NSError *, id responseObject,int current);
@property (nonatomic, strong) void(^multiprogressHandler)(float pre,int current);
@property (nonatomic, strong) void(^progressHandler)(float pre);
@property (nonatomic,strong)void(^reachableBlock)(BOOL val);
@property (nonatomic)int currentVal;
@property (nonatomic,strong)NSString *currentFile;
-(void)basicURL: (NSString*) myURL : (void (^)(NSError *error, id returnObject))handler;
+ (UrlHandler*)sharedInstance;
-(void)initCache;
-(void)isNetWorking : (void(^)(BOOL val))callBack;
-(void)downloadFileWithURL:(NSString*)myURL
withName:(NSString*)fileName
progressBlock:(void (^)(float pre))progress
completionBlock:(void (^)(NSError *error, id returnObject))handler;
-(void)downloadListOfListWithArray:(NSArray*)fileList
progressBlock:(void (^)(float pre,int current))progress
completionBlock:(void (^)(NSError *error, id returnObject,int currentObj))handler;
@end
