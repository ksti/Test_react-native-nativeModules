//
//  BluetoothManager.h
//  YuanXinBluetooth
//
//  Created by GJS on 2017/5/25.
//  Copyright © 2017年 GJS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YuanXinBluetooth.h"
#import "BabyBluetooth.h"
#import "BluetoothPeripheralObject.h"
#import "BluetoothCharacteristicObject.h"
#import "MMReceiptManager.h"
#import "MMQRCode.h"
#import "PeripheralInfo.h"
#import "ReceiptInfo.h"

#define Notification_DiscoverNewPeripheral @"DiscoverNewPeripheral"

/**
 * block 
 */
// 主设备状态更新回调
typedef void (^OnCentralManagerDidUpdateState)(CBCentralManager *central);

// 主设备扫描发现回调
typedef void (^OnDiscoverToPeripherals)(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI);
typedef void (^OnDiscoverCharacteristics)(CBPeripheral *peripheral, CBService *service, NSError *error);
typedef void (^OnReadValueForCharacteristic)(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error);
typedef void (^OnDiscoverDescriptorsForCharacteristic)(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error);
typedef void (^OnReadValueForDescriptors)(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error);

// 主设备连接到外设回调
typedef void (^OnConnectedAtChannel)(NSString *channel, CBCentralManager *central, CBPeripheral *peripheral);
typedef void (^OnFailToConnectAtChannel)(NSString *channel, CBCentralManager *central, CBPeripheral *peripheral, NSError *error);

// 主设备读取外设数据回调
typedef void (^OnReadValueForCharacteristicAtChannel)(NSString *channel, CBPeripheral *peripheral,CBCharacteristic *characteristic,NSError *error);
typedef void (^OnReadValueForDescriptorAtChannel)(NSString *channel, CBPeripheral *peripheral,CBDescriptor *descriptor,NSError *error);
typedef void (^OnDidWriteValueForCharacteristicAtChannel)(NSString *channel, CBCharacteristic *characteristic,NSError *error);

@interface BluetoothManager : NSObject

@property (nonatomic, readonly) BabyBluetooth *baby;
@property (nonatomic, readonly) CBManagerState bluetoothState;
@property(nonatomic, getter=isBabyInited) BOOL babyInited;

#pragma mark -主设备状态更新回调

@property (nonatomic, copy) OnCentralManagerDidUpdateState onCentralManagerDidUpdateState; // 设置状态改变的回调
@property (nonatomic, copy) OnFailToConnectAtChannel onFailToConnectAtChannel; // 设置状态改变的回调

#pragma mark -主设备扫描发现回调

@property (nonatomic, copy) OnDiscoverToPeripherals onDiscoverToPeripherals; // 设置扫描到设备的回调

#pragma mark -主设备连接到外设回调

@property (nonatomic, copy) OnConnectedAtChannel onConnectedAtChannel; // 连接到外设时的回调

#pragma mark -主设备读取外设数据回调

@property (nonatomic, copy) OnReadValueForCharacteristicAtChannel onReadValueForCharacteristicAtChannel; // 读取特征值时的回调
@property (nonatomic, copy) OnReadValueForDescriptorAtChannel onReadValueForDescriptorAtChannel; // 读取特征的描述时的回调
@property (nonatomic, copy) OnDidWriteValueForCharacteristicAtChannel onDidWriteValueForCharacteristicAtChannel; // 给特征写入值成功时的回调

#pragma mark -单例构造方法

/**
 * 单例构造方法
 * @return BluetoothManager共享实例
 */
+ (instancetype)shareInstance;

#pragma mark -主设备连接配对

/**
 * 设置蓝牙使用的参数参数
 * @param 
 * @scanForPeripheralsWithOptions (NSDictionary *) 扫描选项，示例 --> CBCentralManagerScanOptionAllowDuplicatesKey:忽略同一个Peripheral端的多个发现事件被聚合成一个发现事件
 * @connectPeripheralWithOptions (NSDictionary *) 连接设备的参数，示例 --> CBConnectPeripheralOptionNotifyOnConnectionKey: 值为Boolean值，决定当应用挂起时在成功连接到外设的时候，是否由系统弹出提示
 * @scanForPeripheralsWithServices (NSArray *) 数组serviceUUIDs: 要扫描的服务(CBUUID)，广播任何其中一个service服务的peripherals外设都会被扫描到
 * @discoverWithServices (NSArray *) 数组serviceUUIDs: 要发现的服务类型(CBUUID)，如果传nil，会搜索外设提供的所有服务，不推荐，会导致效率降低
 * @discoverWithCharacteristics (NSArray *) 数组serviceUUIDs: 要发现的特征类型(CBUUID)，如果传nil，会搜索外设某个服务提供的所有特征数据，不推荐，会导致效率降低
 */
- (void)setBabyOptionsWithScanForPeripheralsWithOptions:(NSDictionary *) scanForPeripheralsWithOptions
                           connectPeripheralWithOptions:(NSDictionary *) connectPeripheralWithOptions
                         scanForPeripheralsWithServices:(NSArray *)scanForPeripheralsWithServices
                                   discoverWithServices:(NSArray *)discoverWithServices
                            discoverWithCharacteristics:(NSArray *)discoverWithCharacteristics;

#pragma mark -主设备扫描过滤规则

/**
 设置查找Peripherals的规则
 |  filter of discover peripherals
 */
- (void)setFilterOnDiscoverPeripherals:(BOOL (^)(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI))filter;

/**
 设置连接Peripherals的规则
 |  setting filter of connect to peripherals  peripherals
 */
- (void)setFilterOnConnectToPeripherals:(BOOL (^)(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI))filter;


/**
 设置查找Peripherals的规则
 |  filter of discover peripherals
 */
- (void)setFilterOnDiscoverPeripheralsAtChannel:(NSString *)channel
                                         filter:(BOOL (^)(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI))filter;

/**
 设置连接Peripherals的规则
 |  setting filter of connect to peripherals  peripherals
 */
- (void)setFilterOnConnectToPeripheralsAtChannel:(NSString *)channel
                                          filter:(BOOL (^)(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI))filter;

#pragma mark -主设备连接外设

/**
 * 开始连接外设
 */
- (void)connectPeripheral:(CBPeripheral *)currPeripheral;
/**
 * 开始连接外设，设置感兴趣的服务
 */
- (void)connectPeripheral:(CBPeripheral *)currPeripheral withDiscoverSevices:(NSArray<CBUUID *> *)servicesToDiscover;

/**
 * 断开连接
 */
- (void)cancelPeripheralConnection:(CBPeripheral *)peripheral;
/**
 * 断开所有连接
 */
- (void)cancelAllPeripheralsConnection;

#pragma mark -主设备自动重连外设

/**
 * 添加断开自动重连的外设
 */
- (void)AutoReconnect:(CBPeripheral *)peripheral;

/**
 * 删除断开自动重连的外设
 */
- (void)AutoReconnectCancel:(CBPeripheral *)peripheral;

/**
 * 根据外设UUID对应的string获取已配对的外设
 
 * 通过方法获取外设后可以直接连接外设，跳过扫描过程
 */
- (CBPeripheral *)retrievePeripheralWithUUIDString:(NSString *)UUIDString;

#pragma mark -工具方法
/**
 * 清除数据
 */
- (void)clearPeripheralsArray;
/**
 * 根据 name 查找外设
 */
- (CBPeripheral *)findPeripheralByName:(NSString *)peripheralName inDiscoveredPeripherals:(NSArray *)connectedPeripherals;
- (CBPeripheral *)findPeripheralByName:(NSString *)peripheralName;
/**
 *  根据 identifier 查找外设
 */
- (CBPeripheral *)findPeripheralByIdentifier:(NSString *)peripheralIdentifier inDiscoveredPeripherals:(NSArray *)connectedPeripherals;
- (CBPeripheral *)findPeripheralByIdentifier:(NSString *)peripheralIdentifier;
/**
 *  根据 UUIDString 查找 characteristic
 */
- (CBCharacteristic *)findCharacteristicByUUIDString:(NSString *)characteristicUUID inDiscoveredServices:(NSArray<PeripheralInfo *> *)discoveredServices;
- (CBCharacteristic *)findCharacteristicByUUIDString:(NSString *)characteristicUUID;

#pragma mark -主设备读取外设提供的服务、特征
/**
 *  读取外设提供的服务、特征
 */
- (NSArray<PeripheralInfo *> *)getPeripheralServices;

/**
 设置characteristic的notify
 */
- (void)notify:(CBPeripheral *)peripheral
characteristic:(CBCharacteristic *)characteristic
         block:(void(^)(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error))block;

/**
 取消characteristic的notify
 */
- (void)cancelNotify:(CBPeripheral *)peripheral
      characteristic:(CBCharacteristic *)characteristic;

// 读取Characteristic的详细信息
- (void)readPeripheral:(CBPeripheral *)peripheral characteristicDetails:(CBCharacteristic *)characteristic;
// 读取Characteristic的详细信息
- (void)readPeripheral:(CBPeripheral *)peripheral characteristicUUIDString:(NSString *)characteristicUUIDString;

// 向蓝牙发送信息
- (void)writePeripheral:(CBPeripheral *)peripheral dataWithString:(NSString *)str orInfoData:(NSData *)infoData forCharacteristic:(CBCharacteristic *)characteristic;
// 向蓝牙发送信息
- (void)writePeripheral:(CBPeripheral *)peripheral dataWithString:(NSString *)str orInfoData:(NSData *)infoData forCharacteristicUUIDString:(NSString *)characteristicUUIDString;

#pragma mark -蓝牙打印小票
//基础设置
- (void)printerBasicSetting;
//清空缓存数据
- (void)printerClearData;
//写入单行文字
- (void)printerWriteData_title:(NSString *)title Scale:(kCharScale)scale Type:(kAlignmentType)type;
//打印图片
- (void)printerWriteData_image:(UIImage *)image alignment:(kAlignmentType)alignment maxWidth:(CGFloat)maxWidth;
//打印图片
- (void)printerWriteData_qrImageStr:(NSString *)qrImageStr alignment:(kAlignmentType)alignment maxWidth:(CGFloat)maxWidth;
//写入多行文字
- (void)printerWriteData_items:(NSArray *)items;
//打印分割线
- (void)printerWriteData_line;
//条目,菜单,有间隔,如:
//  炸鸡排     2      12.50      25.00
- (void)printerWriteData_content:(NSArray *)items;

// 打印小票
- (void)receiptPrint:(CBPeripheral *)peripheral forCharacteristic:(CBCharacteristic *)characteristic;

@end
