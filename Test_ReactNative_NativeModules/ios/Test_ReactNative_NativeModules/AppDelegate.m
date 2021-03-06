/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "AppDelegate.h"

#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>

#import "TestRootViewController.h"
#import "NavigationController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSURL *jsCodeLocation;
    
    [[RCTBundleURLProvider sharedSettings] setDefaults];
    [[RCTBundleURLProvider sharedSettings] setJsLocation:@"10.23.89.159"];
    jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index.ios" fallbackResource:nil];

    RCTRootView *rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                        moduleName:@"Test_ReactNative_NativeModules"
                                                 initialProperties:nil
                                                     launchOptions:launchOptions];
    rootView.backgroundColor = [[UIColor alloc] initWithRed:1.0f green:1.0f blue:1.0f alpha:1];

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    UIViewController *rootViewController = [UIViewController new];
    rootViewController.view = rootView;
    self.window.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];
    
    // set native ViewController for test
    //[self setNativeViewControllerForTest];
    
    return YES;
}

- (void)setRootViewController:(UIViewController *)rootViewController {
    self.window.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];
}

- (void)setNativeViewControllerForTest {
    TestRootViewController *rootViewController = [TestRootViewController new];
    //TestRootViewController *rootViewController = [[TestRootViewController alloc] initWithNibName:@"TestRootViewController" bundle:nil];
    self.navigationController = [[NavigationController alloc] initWithNibName:@"NavigationController" bundle:nil];
    self.navigationController = [self.navigationController initWithRootViewController:rootViewController];
    [self setRootViewController:self.navigationController];
}

@end
