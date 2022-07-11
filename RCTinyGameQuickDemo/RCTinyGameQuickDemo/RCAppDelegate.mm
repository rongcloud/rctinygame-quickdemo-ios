#import "RCAppDelegate.h"
#import <RongIMLibCore/RongIMLibCore.h>
#import "User.h"
#import "UserManager.h"
#import "LoginViewController.h"
#import "LaunchManager.h"
#import "GameListViewController.h"
//#import <IQKeyboardManager.h>


@implementation RCAppDelegate

/*
 融云key可在开发者后台获取
 demo使用的是临时token，可以在开发者后台调用接口获得
 正式环境中，请从自己的服务器通过接口获取
 */
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [SVProgressHUD setMaximumDismissTimeInterval:1.5];
    
    
//    self.window.windowLevel = 100;
//    [IQKeyboardManager sharedManager].enable = YES;
//    [IQKeyboardManager sharedManager].enableAutoToolbar = NO;

    RCGameService.rcBaseUrl = @"https://rcrtc-api.rongcloud.net/";
    RCGameService.rcBusinessToken = @"gKDlVu1kTqMv91hqntCI3Y";
    
    UIViewController *rootVC;
    if ([UserManager isLogin]) {
        RCGameService.authorization = [UserManager sharedManager].currentUser.authorization;
        rootVC = [[GameListViewController alloc] init];
        //LaunchManager初始化语音房SDK
        [LaunchManager initSDKWithAppKey:AppKey imToken:[UserManager sharedManager].currentUser.token completion:^(BOOL success, RCConnectErrorCode code) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"连接融云成功，当前id%@", [UserManager sharedManager].currentUser.userId]];
                    Log("voice sdk initializ success");
                } else {
                    [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"连接融云失败 code: %ld",code]];
                    Log("voice sdk initializ fail %ld",(long)code);
                }
            });
        }];
    } else {
        rootVC = [[LoginViewController alloc] initWithHomeViewController:[[GameListViewController alloc] init]];
    }

    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:rootVC];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[RCGameEngine shared] resumeEngine];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[RCGameEngine shared] pauseEngine];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    
}

@end
    

