urlHandler
==========

Easy way to work with NSURL in Objective-C 

How to use :

initCache in AppDelegate didFinishLaunchingWithOptions 

	[[UrlHandler sharedInstance] initCache];


Basic URL request .

	[[UrlHandler sharedInstance] basicURL:@"http://google.com" :^(NSError *error, id returnObject) {
	    if(error != (NSError*)[NSNull null] && ![returnObject isEqualToString:@"notReachable"]){
	        NSLog(@"returnObject : %@",returnObject);
	    }else{
	        NSLog(@"error : %@",error);
	    }
	}];


Download File with progress .

	[[UrlHandler sharedInstance] downloadFileWithURL:@"http://www.socialtalent.co/wp-content/uploads/blog-content/so-logo.png" withName:@"logo.png" progressBlock:^(float pre) {
	        NSLog(@"progress :%f",pre);
	    } completionBlock:^(NSError *error, id returnObject) {
	        NSLog(@"error : %@:%@",error,returnObject);
	    }];