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
-(void)testURL: (NSString*) myURL : (void (^)(NSError *error, id returnObject))handler;
+ (UrlHandler*)sharedInstance;
-(void)initCache;
@end
