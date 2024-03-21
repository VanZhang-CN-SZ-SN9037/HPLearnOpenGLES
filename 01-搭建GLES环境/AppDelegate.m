//
//  AppDelegate.m
//  01-搭建GLES环境
//
//  Created by Van Zhang on 2024/3/21.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    _window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    [_window setRootViewController: [[ViewController alloc]init]];
    [_window makeKeyAndVisible];
    return YES;
}

@end
