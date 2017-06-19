//
//  BluetoothPeripheralObject.m
//  YuanXinBluetooth
//
//  Created by GJS on 2017/6/5.
//  Copyright © 2017年 GJS. All rights reserved.
//

#import "BluetoothPeripheralObject.h"

#define kChannelOnPeripheral @"ChannelOnPeripheral"

@implementation BluetoothPeripheralObject

- (instancetype)init
{
    return [self initWithChannel:kChannelOnPeripheral];
}

- (instancetype)initWithChannel:(NSString *)channel {
    self = [super init];
    if (self) {
        //初始化
        _currChannel = kChannelOnPeripheral;
        if (channel) {
            _currChannel = channel;
        }
        self.services = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void)setBaby:(BabyBluetooth *)baby {
    if (baby && _baby != baby) {
        _baby = baby;
        // 清空数据
        [self clearData];
        // 配置ble委托
        [self babyConnectDelegate];
    }
}

// 清空数据
- (void)clearData {
    [self.services removeAllObjects];
}

//babyDelegate
-(void)babyConnectDelegate {
    
    __weak typeof(self)weakSelf = self;
    BabyRhythm *rhythm = [[BabyRhythm alloc]init];
    
    //设置设备连接成功的委托,同一个baby对象，使用不同的channel切换委托回调
    [_baby setBlockOnConnectedAtChannel:_currChannel block:^(CBCentralManager *central, CBPeripheral *peripheral) {
        NSLog(@"设备：%@--连接成功",peripheral.name);
        if (weakSelf.onConnectedPeripheral) {
            weakSelf.onConnectedPeripheral(central, peripheral);
        }
    }];
    
    //设置设备连接失败的委托
    [_baby setBlockOnFailToConnectAtChannel:_currChannel block:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备：%@--连接失败",peripheral.name);
        if (weakSelf.onFailToConnectPeripheral) {
            weakSelf.onFailToConnectPeripheral(central, peripheral, error);
        }
    }];
    
    //设置设备断开连接的委托
    [_baby setBlockOnDisconnectAtChannel:_currChannel block:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备：%@--断开连接",peripheral.name);
        if (weakSelf.onDisconnectPeripheral) {
            weakSelf.onDisconnectPeripheral(central, peripheral, error);
        }
    }];
    
    //设置发现设备的Services的委托
    [_baby setBlockOnDiscoverServicesAtChannel:_currChannel block:^(CBPeripheral *peripheral, NSError *error) {
        for (CBService *s in peripheral.services) {
            //插入section到tableview
            [weakSelf insertService:s];
        }
        
        [rhythm beats];
    }];
    //设置发现设service的Characteristics的委托
    [_baby setBlockOnDiscoverCharacteristicsAtChannel:_currChannel block:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        NSLog(@"===service name:%@",service.UUID);
        //插入row到tableview
        [weakSelf insertCharacteristicsFromService:service];
    }];
    //设置读取characteristics的委托
    [_baby setBlockOnReadValueForCharacteristicAtChannel:_currChannel block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        NSLog(@"characteristic name:%@ value is:%@",characteristics.UUID,characteristics.value);
    }];
    //设置发现characteristics的descriptors的委托
    [_baby setBlockOnDiscoverDescriptorsForCharacteristicAtChannel:_currChannel block:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"===characteristic name:%@",characteristic.service.UUID);
        for (CBDescriptor *d in characteristic.descriptors) {
            NSLog(@"CBDescriptor name is :%@",d.UUID);
        }
    }];
    //设置读取Descriptor的委托
    [_baby setBlockOnReadValueForDescriptorsAtChannel:_currChannel block:^(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) {
        NSLog(@"Descriptor name:%@ value is:%@",descriptor.characteristic.UUID, descriptor.value);
    }];
    
    //读取rssi的委托
    [_baby setBlockOnDidReadRSSI:^(NSNumber *RSSI, NSError *error) {
        NSLog(@"setBlockOnDidReadRSSI:RSSI:%@",RSSI);
    }];
    
    
    //设置beats break委托
    [rhythm setBlockOnBeatsBreak:^(BabyRhythm *bry) {
        NSLog(@"setBlockOnBeatsBreak call");
        
        //如果完成任务，即可停止beat,返回bry可以省去使用weak rhythm的麻烦
        //        if (<#condition#>) {
        //            [bry beatsOver];
        //        }
        
    }];
    
    //设置beats over委托
    [rhythm setBlockOnBeatsOver:^(BabyRhythm *bry) {
        NSLog(@"setBlockOnBeatsOver call");
    }];
    
    //扫描选项->CBCentralManagerScanOptionAllowDuplicatesKey:忽略同一个Peripheral端的多个发现事件被聚合成一个发现事件
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    /*连接选项->
     CBConnectPeripheralOptionNotifyOnConnectionKey :当应用挂起时，如果有一个连接成功时，如果我们想要系统为指定的peripheral显示一个提示时，就使用这个key值。
     CBConnectPeripheralOptionNotifyOnDisconnectionKey :当应用挂起时，如果连接断开时，如果我们想要系统为指定的peripheral显示一个断开连接的提示时，就使用这个key值。
     CBConnectPeripheralOptionNotifyOnNotificationKey:
     当应用挂起时，使用该key值表示只要接收到给定peripheral端的通知就显示一个提示
     */
    NSDictionary *connectOptions = @{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,
                                     CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES,
                                     CBConnectPeripheralOptionNotifyOnNotificationKey:@YES};
    
    [_baby setBabyOptionsAtChannel:_currChannel scanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:connectOptions scanForPeripheralsWithServices:nil discoverWithServices:self.servicesToDiscover discoverWithCharacteristics:nil];
    
}

// 开始连接设备
- (void)connectPeripheral {
    [self connectPeripheral:self.currPeripheral];
}
- (void)connectPeripheral:(CBPeripheral *)currPeripheral {
    _baby.having(currPeripheral).and.channel(_currChannel).then.connectToPeripherals().discoverServices().discoverCharacteristics().readValueForCharacteristic().discoverDescriptorsForCharacteristic().readValueForDescriptors().begin();
    //    baby.connectToPeripheral(self.currPeripheral).begin();
}

#pragma mark -插入 services 数据
-(void)insertService:(CBService *)service{
    NSLog(@"搜索到服务:%@",service.UUID.UUIDString);
    PeripheralInfo *info = [[PeripheralInfo alloc]init];
    [info setServiceUUID:service.UUID];
    [self.services addObject:info];
}

-(void)insertCharacteristicsFromService:(CBService *)service{
    int serviceIndex = -1;
    for (int i=0;i<self.services.count;i++) {
        PeripheralInfo *info = [self.services objectAtIndex:i];
        if (info.serviceUUID == service.UUID) {
            serviceIndex = i;
            break;
        }
    }
    if (serviceIndex != -1) {
        PeripheralInfo *info =[self.services objectAtIndex:serviceIndex];
        for (int row=0;row<service.characteristics.count;row++) {
            CBCharacteristic *c = service.characteristics[row];
            [info.characteristics addObject:c];
        }
        //PeripheralInfo *curInfo =[self.services objectAtIndex:serviceIndex];
        //NSLog(@"%@",curInfo.characteristics);
    }
}

@end
