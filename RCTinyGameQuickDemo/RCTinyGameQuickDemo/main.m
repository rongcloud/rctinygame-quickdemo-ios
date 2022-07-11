
@import UIKit;
#import "RCAppDelegate.h"
//#include <UnityFramework/UnityFramework.h>

//UnityFramework* UnityFrameworkLoad()
//{
//    NSString* bundlePath = nil;
//    bundlePath = [[NSBundle mainBundle] bundlePath];
//    bundlePath = [bundlePath stringByAppendingString: @"/Frameworks/UnityFramework.framework"];
//
//    NSBundle* bundle = [NSBundle bundleWithPath: bundlePath];
//    if ([bundle isLoaded] == false) [bundle load];
//
//    UnityFramework* ufw = [bundle.principalClass getInstance];
//    if (![ufw appController])
//    {
//        // unity is not initialized
//        [ufw setExecuteHeader: &_mh_execute_header];
//    }
//    return ufw;
//}

int main(int argc, char * argv[])
{
    @autoreleasepool {
        NSURL *url = [NSURL URLWithString:@"https://www.baidu.com"];//此处修改为自己公司的服务器地址
           NSURLRequest *request = [NSURLRequest requestWithURL:url];
           NSURLSession *session = [NSURLSession sharedSession];
           NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
               if (error == nil) {
                   NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                   NSLog(@"%@",dict);
               }
           }];
           [dataTask resume];
//        [UnityFrameworkLoad() runUIApplicationMainWithArgc: argc argv: argv];
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([RCAppDelegate class]));
    }
}
