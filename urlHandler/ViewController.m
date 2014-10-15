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
    [[UrlHandler sharedInstance] basicURL:@"http://google.com" :^(NSError *error, id returnObject) {
        if(error != (NSError*)[NSNull null] && ![returnObject isEqualToString:@"notReachable"]){
            NSLog(@"returnObject : %@",returnObject);
        }else{
            NSLog(@"error : %@",error);
        }
    }];
    
    [[UrlHandler sharedInstance] downloadFileWithURL:@"http://spaceflight.nasa.gov/gallery/images/apollo/apollo17/hires/s72-55482.jpg" withName:@"img.png" progressBlock:^(float pre) {
        NSLog(@"progress :%f",pre);
    } completionBlock:^(NSError *error, id returnObject) {
        NSLog(@"error : %@:%@",error,returnObject);
    }];
}
-(void)testURLFunction{
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
