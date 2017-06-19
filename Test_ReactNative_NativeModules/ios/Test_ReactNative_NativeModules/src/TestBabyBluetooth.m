//
//  TestBabyBluetooth.m
//  Test_ReactNative_NativeModules
//
//  Created by GJS on 2017/5/12.
//  Copyright © 2017年 GJS. All rights reserved.
//

#import "TestBabyBluetooth.h"

#define channelOnPeropheralView @"peripheralView"

@interface TestBabyBluetooth() {
    NSMutableArray *peripheralDataArray;
    BabyBluetooth *baby;
}

@end

@implementation TestBabyBluetooth

@synthesize baby;

- (instancetype)init
{
    self = [super init];
    if (self) {
        //
        peripheralDataArray = [[NSMutableArray alloc] init];
        
        //初始化BabyBluetooth 蓝牙库
        baby = [BabyBluetooth shareBabyBluetooth];
        //设置蓝牙委托
        [self babyDelegate];
        //设置委托后直接可以使用，无需等待CBCentralManagerStatePoweredOn状态
        //baby.scanForPeripherals().begin();
    }
    return self;
}

- (void)dealloc {
    // 2s后，停止扫描，断开连接
    baby.stop(2);
}

#pragma mark -蓝牙配置和操作

//蓝牙网关初始化和委托方法设置
- (void)babyDelegate {
    
    __weak typeof(self) weakSelf = self;
    [baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        /*!
         *  @enum CBManagerState
         *
         *  @discussion Represents the current state of a CBManager.
         *
         *  @constant CBManagerStateUnknown       State unknown, update imminent.
         *  @constant CBManagerStateResetting     The connection with the system service was momentarily lost, update imminent.
         *  @constant CBManagerStateUnsupported   The platform doesn't support the Bluetooth Low Energy Central/Client role.
         *  @constant CBManagerStateUnauthorized  The application is not authorized to use the Bluetooth Low Energy role.
         *  @constant CBManagerStatePoweredOff    Bluetooth is currently powered off.
         *  @constant CBManagerStatePoweredOn     Bluetooth is currently powered on and available to use.
         *
         */
        NSString *message = nil;
        switch (central.state) {
            case CBManagerStateUnsupported:
                message = @"该设备不支持蓝牙功能,请检查系统设置";
                break;
            case CBManagerStateUnauthorized:
                message = @"该设备蓝牙未授权,请检查系统设置";
                break;
            case CBManagerStatePoweredOff:
                message = @"该设备尚未打开蓝牙,请在设置中打开";
                break;
            case CBManagerStatePoweredOn:
                message = @"蓝牙已经成功开启";
                break;
            default:
                break;
        }
        if (central.state == CBCentralManagerStatePoweredOn) {
            NSLog(@"设备打开成功");
        }
    }];
    
    //设置扫描到设备的委托
    [baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        NSLog(@"搜索到了设备:%@",peripheral.name);
        NSLog(@"%@ 附带 advertisementData:%@", peripheral.name, advertisementData);
        NSLog(@"%@ 附带 RSSI:%@", peripheral.name, RSSI);
        [weakSelf insertPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
    }];
    
    
    //设置发现设service的Characteristics的委托
    [baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        NSLog(@"===service name:%@",service.UUID);
        for (CBCharacteristic *c in service.characteristics) {
            NSLog(@"charateristic name is :%@",c.UUID);
        }
    }];
    //设置读取characteristics的委托
    [baby setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        NSLog(@"characteristic name:%@ value is:%@",characteristics.UUID,characteristics.value);
    }];
    //设置发现characteristics的descriptors的委托
    [baby setBlockOnDiscoverDescriptorsForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"===characteristic name:%@",characteristic.service.UUID);
        for (CBDescriptor *d in characteristic.descriptors) {
            NSLog(@"CBDescriptor name is :%@",d.UUID);
        }
    }];
    //设置读取Descriptor的委托
    [baby setBlockOnReadValueForDescriptors:^(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) {
        NSLog(@"Descriptor name:%@ value is:%@",descriptor.characteristic.UUID, descriptor.value);
    }];
    
    
    //设置查找设备的过滤器
    [baby setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        
        //最常用的场景是查找某一个前缀开头的设备
        //        if ([peripheralName hasPrefix:@"Pxxxx"] ) {
        //            return YES;
        //        }
        //        return NO;
        
        //设置查找规则是名称大于0 ， the search rule is peripheral.name length > 0
        if (peripheralName.length >0) {
            return YES;
        }
        return NO;
    }];
    
    
    [baby setBlockOnCancelAllPeripheralsConnectionBlock:^(CBCentralManager *centralManager) {
        NSLog(@"setBlockOnCancelAllPeripheralsConnectionBlock");
    }];
    
    [baby setBlockOnCancelScanBlock:^(CBCentralManager *centralManager) {
        NSLog(@"setBlockOnCancelScanBlock");
    }];
    
    
    /*设置babyOptions
     
     参数分别使用在下面这几个地方，若不使用参数则传nil
     - [centralManager scanForPeripheralsWithServices:scanForPeripheralsWithServices options:scanForPeripheralsWithOptions];
     - [centralManager connectPeripheral:peripheral options:connectPeripheralWithOptions];
     - [peripheral discoverServices:discoverWithServices];
     - [peripheral discoverCharacteristics:discoverWithCharacteristics forService:service];
     
     该方法支持channel版本:
     [baby setBabyOptionsAtChannel:<#(NSString *)#> scanForPeripheralsWithOptions:<#(NSDictionary *)#> connectPeripheralWithOptions:<#(NSDictionary *)#> scanForPeripheralsWithServices:<#(NSArray *)#> discoverWithServices:<#(NSArray *)#> discoverWithCharacteristics:<#(NSArray *)#>]
     */
    
    //示例:
    //扫描选项->CBCentralManagerScanOptionAllowDuplicatesKey:忽略同一个Peripheral端的多个发现事件被聚合成一个发现事件
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    //连接设备->
    [baby setBabyOptionsWithScanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:nil scanForPeripheralsWithServices:nil discoverWithServices:nil discoverWithCharacteristics:nil];
    
    
}

#pragma mark -utils

// 插入 peripheral 数据
-(void)insertPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    NSArray *peripherals = [peripheralDataArray valueForKey:@"peripheral"];
    if(![peripherals containsObject:peripheral]) {
        NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
        [item setValue:peripheral forKey:@"peripheral"];
        [item setValue:RSSI forKey:@"RSSI"]; // 信号和服务
        [item setValue:advertisementData forKey:@"advertisementData"];
        [peripheralDataArray addObject:item];
        
        // peripheral的显示名称,优先用kCBAdvDataLocalName的定义，若没有再使用peripheral name
        NSString *peripheralName;
        if ([advertisementData objectForKey:@"kCBAdvDataLocalName"]) {
            peripheralName = [NSString stringWithFormat:@"%@",[advertisementData objectForKey:@"kCBAdvDataLocalName"]];
        }else if(!([peripheral.name isEqualToString:@""] || peripheral.name == nil)){
            peripheralName = peripheral.name;
        }else{
            peripheralName = [peripheral.identifier UUIDString];
        }
        NSLog(@"discovered a new peripheral: %@", peripheralName);
        
        [self postNotificationName:Notification_DiscoverNewPeripheral object:peripheralDataArray];
    }
}

// 发送通知
- (void)postNotificationName:(NSString*)name object:(id)object {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter postNotificationName:name object:object];
}

@end
