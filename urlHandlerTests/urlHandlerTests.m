//
//  urlHandlerTests.m
//  urlHandlerTests
//
//  Created by Rahul Malik on 12/10/14.
//  Copyright (c) 2014 Rahul Malik. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "UrlHandler.h"

@interface urlHandlerTests : XCTestCase

@end

@implementation urlHandlerTests

NSString *baseURL = @"https://httpbin.org/";

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBasic{
    NSString *description = [NSString stringWithFormat:@"GET %@", baseURL];
    XCTestExpectation *expectation = [self expectationWithDescription:description];
    __block BOOL testBool = false;
    [[UrlHandler sharedInstance] basicURL:baseURL :^(NSError *error, id returnObject) {
        if(error != (NSError*)[NSNull null] && ![returnObject isEqualToString:@"notReachable"]){
            testBool = true;
            [expectation fulfill];
        }else{
            testBool = false;
        }
    }];
    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError * _Nullable error) {
        
    }];
    XCTAssert(testBool, @"basic URL test");
}
- (void)testDownload{
    NSString *description = [NSString stringWithFormat:@"GET %@ : download", baseURL];
    XCTestExpectation *expectation = [self expectationWithDescription:description];
    __block BOOL testBool = false;
    NSString *finalURL = [baseURL stringByAppendingString:@"image/png"];
    [[UrlHandler sharedInstance] downloadFileWithURL:finalURL withName:@"img.png" progressBlock:^(float pre) {
        NSLog(@"progress :%f",pre);
    } completionBlock:^(NSError *error, id returnObject) {
        NSLog(@"error : %@:%@",error,returnObject);
        [expectation fulfill];
        testBool = true;
    }];
    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError * _Nullable error) {
        
    }];
    XCTAssert(testBool, @"basic download test");
}

-(void)testMultiDownload{
    NSString *description = [NSString stringWithFormat:@"GET %@ : MultiDownload", baseURL];
    XCTestExpectation *expectation = [self expectationWithDescription:description];
    __block BOOL testBool = false;
    NSString *finalURL = [baseURL stringByAppendingString:@"image/png"];
    NSArray *array = @[finalURL];
   [[UrlHandler sharedInstance] downloadListOfListWithArray:array progressBlock:^(float pre, int current) {
        NSLog(@"progress :%f:%d",pre,current);
    } completionBlock:^(NSError *error, id returnObject, int currentObj) {
        [expectation fulfill];
        testBool = true;
        NSLog(@"error : %@:%@:%d",error,returnObject,currentObj);
    }];
    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError * _Nullable error) {
        
    }];
    XCTAssert(testBool, @"Multiple Download files test");
}

-(void)testForm{
    NSString *description = [NSString stringWithFormat:@"POST %@ formRequest", baseURL];
    XCTestExpectation *expectation = [self expectationWithDescription:description];
    __block BOOL testBool = false;
    NSString *finalURL = [baseURL stringByAppendingString:@"post"];
    NSDictionary *dic = @{
                          @"name":@"awesome",
                          @"email":@"awesome@cool.awesome",
                          };
    [[UrlHandler sharedInstance] basicFormURL:finalURL :@"POST" :dic :^(NSError *error, id returnObject) {
        if(error != (NSError*)[NSNull null] && ![returnObject isEqualToString:@"notReachable"]){
            NSLog(@"returnObject : %@",returnObject);
            NSData *webData = [returnObject dataUsingEncoding:NSUTF8StringEncoding];
            NSError *error;
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:webData options:0 error:&error];
            NSDictionary *getFormObject = (NSDictionary*)[jsonDict valueForKey:@"form"];
            if ([getFormObject[@"name"]  isEqual: @"awesome"] && [getFormObject[@"email"]  isEqual: @"awesome@cool.awesome"]){
                testBool = true;
            }else{
                testBool = false;
            }
            [expectation fulfill];
        }else{
            NSLog(@"error : %@",error);
        }
    }];
    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError * _Nullable error) {
        
    }];
    XCTAssert(testBool, @"basic form post request test");
}

-(void)testFormRequestWithFile{
    NSString *description = [NSString stringWithFormat:@"POST %@ form with File", baseURL];
    XCTestExpectation *expectation = [self expectationWithDescription:description];
    __block BOOL testBool = false;
    NSString *finalURL = [baseURL stringByAppendingString:@"post"];
    NSData *imageData = UIImageJPEGRepresentation([UIImage imageNamed:@"img.png"], 90);
    NSDictionary *fileInfo = @{ @"data":imageData, @"contentType":@"image/jpeg", @"fileName":@"image.jpeg", @"key":@"userfile" };
    NSDictionary* dic = @{
                          @"comment":@"this is a comment",
                          @"email":@"awesome@cool.awesome",
                          @"pincode":@"100000",
                          @"name":@"Rahul Emosewa",
                          @"phone":@"9821829923",
                          @"file":fileInfo
                          };
    [[UrlHandler sharedInstance] multipleFormUrl:finalURL :@"POST" postDictionary:dic progressBlock:^(float pre) {
        NSLog(@"progress :%f",pre);
    } completionBlock:^(NSError *error, id returnObject) {
        NSLog(@"error : %@:%@",error,returnObject);
        NSDictionary *getFormObject = (NSDictionary*)[returnObject valueForKey:@"form"];
        NSData *filesInfoObject = [[returnObject valueForKey:@"files"] valueForKey:@"userfile"];
        if ([filesInfoObject isEqual:fileInfo]){
            //awesome file are also matching
        }
        if ([getFormObject[@"name"]  isEqual: @"Rahul Emosewa"] && [getFormObject[@"phone"]  isEqual: @"9821829923"] && [getFormObject[@"email"] isEqual:@"awesome@cool.awesome" ] && [getFormObject[@"comment"] isEqual:@"this is a comment"]){
            testBool = true;
        }else{
            testBool = false;
        }
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError * _Nullable error) {
        
    }];
    XCTAssert(testBool, @"Multiple Download files test");
}

@end
