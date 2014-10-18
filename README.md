urlHandler
==========

Easy way to work with NSURL in Objective-C 

How to use :

initCache in AppDelegate didFinishLaunchingWithOptions 
```objective-c
	[[UrlHandler sharedInstance] initCache];
```


Basic URL request .
```objective-c
	[[UrlHandler sharedInstance] basicURL:@"http://google.com" :^(NSError *error, id returnObject) {
	    if(error != (NSError*)[NSNull null] && ![returnObject isEqualToString:@"notReachable"]){
	        NSLog(@"returnObject : %@",returnObject);
	    }else{
	        NSLog(@"error : %@",error);
	    }
	}];
```


Download File with progress .
```objective-c
	[[UrlHandler sharedInstance] downloadFileWithURL:@"http://www.socialtalent.co/wp-content/uploads/blog-content/so-logo.png" withName:@"logo.png" progressBlock:^(float pre) {
	    NSLog(@"progress :%f",pre);
	} completionBlock:^(NSError *error, id returnObject) {
	    NSLog(@"error : %@:%@",error,returnObject);
	}];
```

Multiple File Downloader with progress .
```objective-c
	NSArray *array = @[@"http://wfiles.brothersoft.com/a/awesome-ice-block_178817-1920x1080.jpg",
	                   @"http://www.hitswallpapers.com/wp-content/uploads/2014/07/awesome-city-wallpapers-1920x1080-2.jpg",
	                   @"http://awesomewallpaper.files.wordpress.com/2011/09/splendorous1920x1080.jpg",
	                   ];
	[[UrlHandler sharedInstance] downloadListOfListWithArray:array progressBlock:^(float pre, int current) {
	    NSLog(@"progress :%f:%d",pre,current);
	} completionBlock:^(NSError *error, id returnObject, int currentObj) {
	    NSLog(@"error : %@:%@:%d",error,returnObject,currentObj);
	}];
```