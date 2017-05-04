//
//  TestRootViewController.m
//  Test_ReactNative_NativeModules
//
//  Created by forp on 2017/5/4.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "TestRootViewController.h"
#import "TestTableViewController.h"

@interface TestRootViewController () {
  TestTableViewController *_testTableVC;
}

@end

@implementation TestRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
		[self loadDefaultSettings];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadDefaultSettings {
    if (!_testTableVC) {
      _testTableVC = [[TestTableViewController alloc] initWithNibName:@"TestTableViewController" bundle:nil];
    }
    //_testTableVC.view.bounds = self.view.bounds;
    [self.view addSubview:_testTableVC.view];
    [self addChildViewController:_testTableVC];
    
    // title
    self.title = @"for test";
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
