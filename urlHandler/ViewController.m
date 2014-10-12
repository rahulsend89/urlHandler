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
    [[UrlHandler sharedInstance] testURL:@"http://atd6.spinr.in/marketing_services/get_tag_list?partner_id=unmu-in&channel_id=unmu-in-ios&tag_name=top20&product_type=item&offset=0&limit=60" :^(NSError *error, id returnObject) {
        NSLog(@"returnObject : %@",returnObject);
    }];
    NSLog(@"the above code is not bloacking down code");
}
-(void)testURLFunction{
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
