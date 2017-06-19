//
//  TestCoreBluetoothPeripheralManager.h
//  Test_ReactNative_NativeModules
//
//  Created by forp on 2017/5/8.
//  Copyright © 2017年 GJS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface TestCoreBluetoothPeripheralManager : NSObject

//系统蓝牙设备管理对象，可以把他理解为主设备，通过他，可以去扫描和链接外设
@property (nonatomic, strong, readonly) CBPeripheralManager *manager;
//用于保存被发现设备
@property (nonatomic, strong, readonly) NSMutableArray *services;

+ (TestCoreBluetoothPeripheralManager *)sharedCoreBluetoothPeripheralManager;

@end
