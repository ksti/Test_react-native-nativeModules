//
//  TestBluetoothViewController.m
//  Test_ReactNative_NativeModules
//
//  Created by forp on 2017/5/4.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "TestBluetoothViewController.h"
#import "TestCoreBluetoothCentralManager.h"
#import "TestBabyBluetooth.h"
#import "BluetoothManager.h"

@interface TestBluetoothViewController () {
    // 蓝牙主设备管理器
    CBCentralManager *_CBCentralManager;
    TestBabyBluetooth *_testBaby;
    BluetoothManager *_testBabyManager;
}

@end

@implementation TestBluetoothViewController

- (TestBabyBluetooth *)testBaby {
    if (!_testBaby) {
        _testBaby = [[TestBabyBluetooth alloc] init];
    }
    return _testBaby;
}

- (BluetoothManager *)testBabyManager {
    if (!_testBabyManager) {
        _testBabyManager = [BluetoothManager shareInstance];
    }
    return _testBabyManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    //_CBCentralManager = [TestCoreBluetoothCentralManager sharedCoreBluetoothCentralManager].manager;
    /*
    if (_CBCentralManager.state == CBManagerStatePoweredOn) {
        [_CBCentralManager scanForPeripheralsWithServices:nil options:nil];
    }
    */
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)actionTestBBscanForPeripherals:(id)sender {
    self.testBaby.baby.scanForPeripherals().begin();
}

- (IBAction)actionTestBBcancelScan:(id)sender {
    // 停止扫描
    [self.testBaby.baby cancelScan];
}

@end
