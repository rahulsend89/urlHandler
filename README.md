urlHandler
==========

Easy way to work with NSURL in Objective-C 

How to use :

	[[UrlHandler sharedInstance] testURL:@"http://google.com" :^(NSError *error, id returnObject) {
	    if(error != (NSError*)[NSNull null] && ![returnObject isEqualToString:@"notReachable"]){
	        NSLog(@"returnObject : %@",returnObject);
	    }else{
	        NSLog(@"error : %@",error);
	    }
	}];