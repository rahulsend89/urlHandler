Pod::Spec.new do |s|
  s.name             = "urlHandler"
  s.version          = "0.1.1"
  s.summary          = "Easy way to work with NSURL in Objective-C."
  s.description      = <<-DESC
                       #urlHandler
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

DESC

  s.homepage         = "http://github.com/rahulsend89/urlHandler"
  s.license          = 'MIT'
  s.author           = { "Rahul Malik" => "rahul.send89@gmail.com" }
  s.source           = { :git => "https://github.com/rahulsend89/urlHandler.git", :tag => s.version.to_s }
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = 'urlHandler/UrlHandler.{h,m}'
  s.dependency 'Reachability'
end
