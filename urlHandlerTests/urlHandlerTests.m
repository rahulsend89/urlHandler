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
- (void) testDownload{
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
    XCTAssert(testBool, @"basic URL test Download");
}
@end
