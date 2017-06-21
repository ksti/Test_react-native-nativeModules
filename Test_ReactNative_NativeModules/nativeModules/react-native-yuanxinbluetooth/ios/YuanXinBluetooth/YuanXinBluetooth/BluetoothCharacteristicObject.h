//
//  BluetoothCharacteristicObject.h
//  YuanXinBluetooth
//
//  Created by GJS on 2017/6/5.
//  Copyright © 2017年 GJS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BabyBluetooth.h"
#import "PeripheralServiceInfo.h"

/**
 * block
 */
typedef void (^OnReadValueForCharacteristic)(CBPeripheral *peripheral,CBCharacteristic *characteristic,NSError *error);
typedef void (^OnReadValueForDescriptor)(CBPeripheral *peripheral,CBDescriptor *descriptor,NSError *error);
typedef void (^OnDidWriteValueForCharacteristic)(CBCharacteristic *characteristic,NSError *error);


@interface BluetoothCharacteristicObject : NSObject

@property(strong,nonatomic)BabyBluetooth *baby;
@property __block NSMutableArray *readValueArray;
@property __block NSMutableArray *descriptors;
@property (nonatomic,strong)CBCharacteristic *characteristic;
@property (nonatomic,strong)CBPeripheral *currPeripheral;
@property(strong,nonatomic)NSString *currChannel;

#pragma mark -主设备读取外设数据时回调

@property (nonatomic, copy) OnReadValueForCharacteristic onReadValueForCharacteristic; // 读取特征值时的回调
@property (nonatomic, copy) OnReadValueForDescriptor onReadValueForDescriptor; // 读取特征的描述时的回调
@property (nonatomic, copy) OnDidWriteValueForCharacteristic onDidWriteValueForCharacteristic; // 给特征写入值成功时的回调

- (instancetype)initWithChannel:(NSString *)channel;

// 读取Characteristic的详细信息
- (void)readCharacteristicDetails;
//写一个值
- (void)writeDataWithString:(NSString *)str orInfoData:(NSData *)infoData;
// 向蓝牙发送信息
- (BOOL)printPeripheral:(CBPeripheral *)peripheral dataWithString:(NSString *)str orInfoData:(NSData *)infoData forCharacteristic:(CBCharacteristic *)characteristic;

@end
