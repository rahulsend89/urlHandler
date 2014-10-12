//
//  ViewController.m
//  urlHandler
//
//  Created by Rahul Malik on 12/10/14.
//  Copyright (c) 2014 Rahul Malik. All rights reserved.
//

#import "ViewController.h"
#import "UrlHandler.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[UrlHandler sharedInstance] testURL:@"http://google.com" :^(NSError *error, id returnObject) {
        if(error != (NSError*)[NSNull null] && ![returnObject isEqualToString:@"notReachable"]){
            NSLog(@"returnObject : %@",returnObject);
        }else{
            NSLog(@"error : %@",error);
        }
    }];
}
-(void)testURLFunction{
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
