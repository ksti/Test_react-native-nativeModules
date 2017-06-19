//
//  BluetoothPeripheralObject.h
//  YuanXinBluetooth
//
//  Created by GJS on 2017/6/5.
//  Copyright © 2017年 GJS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BabyBluetooth.h"
#import "PeripheralInfo.h"

/**
 * block
 */
typedef void (^OnConnectedPeripheral)(CBCentralManager *central,CBPeripheral *peripheral);
typedef void (^OnFailToConnectPeripheral)(CBCentralManager *central, CBPeripheral *peripheral, NSError *error);
typedef void (^OnDisconnectPeripheral)(CBCentralManager *central, CBPeripheral *peripheral, NSError *error);

@interface BluetoothPeripheralObject : NSObject

@property(strong,nonatomic)BabyBluetooth *baby;
@property __block NSMutableArray *services;
@property(strong,nonatomic)CBPeripheral *currPeripheral;
@property(strong,nonatomic)NSString *currChannel;
@property(strong,nonatomic)NSArray *servicesToDiscover;

#pragma mark -主设备连接到外设时回调

@property (nonatomic, copy) OnConnectedPeripheral onConnectedPeripheral; // 连接到外设时的回调
@property (nonatomic, copy) OnFailToConnectPeripheral onFailToConnectPeripheral; // 连接外设失败时的回调
@property (nonatomic, copy) OnDisconnectPeripheral onDisconnectPeripheral; // 断开连接时的回调

- (instancetype)initWithChannel:(NSString *)channel;

// 开始连接外设
- (void)connectPeripheral;
- (void)connectPeripheral:(CBPeripheral *)currPeripheral;

@end
