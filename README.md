urlHandler
==========

[![Build Status](https://travis-ci.org/rahulsend89/urlHandler.svg?branch=master)](https://travis-ci.org/rahulsend89/urlHandler)
[![codecov.io](https://codecov.io/github/rahulsend89/urlHandler/coverage.svg?branch=master)](https://codecov.io/github/rahulsend89/urlHandler?branch=master)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=fla )](http://mit-license.org)
[![Platform](http://img.shields.io/badge/platform-ios-lightgrey.svg?style=flat)](https://developer.apple.com/resources/)

Easy way to work with NSURL in Objective-C 

## CocoaPods

urlHandler is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

``` ruby
pod "urlHandler"
```

## Usage

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

Form Request .
```objective-c
NSDictionary *dic = @{
    @"name":@"awesome",
    @"email":@"awesome@cool.awesome"
};
[[UrlHandler sharedInstance] basicFormURL:@"http://10.0.1.5/testPost.php" :@"POST" :dic :^(NSError *error, id returnObject) {
    if(error != (NSError*)[NSNull null] && ![returnObject isEqualToString:@"notReachable"]){
        NSLog(@"returnObject : %@",returnObject);
    }else{
        NSLog(@"error : %@",error);
    }
}];
```

Form Request with File uploading.
```objective-c
NSData *imageData = UIImageJPEGRepresentation([UIImage imageNamed:@"img.jpg"], 90);
NSDictionary *fileInfo = @{
    @"data":imageData,
    @"contentType":@"image/jpeg",
    @"fileName":@"image.jpeg",
    @"key":@"userfile"
};
dic = @{
                      @"comment":@"this is a comment",
                      @"region":@"awesome@cool.awesome",
                      @"pincode":@"100000",
                      @"name":@"Rahul Emosewa",
                      @"phone":@"9821829923",
                      @"file":fileInfo
                      };
[[UrlHandler sharedInstance] multipleFormUrl:@"http://10.0.1.5/Afrimart_backEnd/post.php" :@"POST" postDictionary:dic progressBlock:^(float pre) {
    NSLog(@"progress :%f",pre);
} completionBlock:^(NSError *error, id returnObject) {
    NSLog(@"error : %@:%@",error,returnObject);
}];
```

## Author

Rahul Malik, rahul.send89@gmail.com

## License

urlHandler is available under the MIT license. See the LICENSE file for more info.
