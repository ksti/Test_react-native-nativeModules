//
//  BluetoothCharacteristicObject.m
//  YuanXinBluetooth
//
//  Created by GJS on 2017/6/5.
//  Copyright © 2017年 GJS. All rights reserved.
//

#import "BluetoothCharacteristicObject.h"

#define kChannelOnCharacteristic @"ChannelOnCharacteristic"

@interface BluetoothCharacteristicObject () {
    BOOL valuePrint;
}

@end

@implementation BluetoothCharacteristicObject

- (instancetype)init
{
    return [self initWithChannel:kChannelOnCharacteristic];
}

- (instancetype)initWithChannel:(NSString *)channel {
    self = [super init];
    if (self) {
        //初始化数据
        _currChannel = kChannelOnCharacteristic;
        if (channel) {
            _currChannel = channel;
        }
        _readValueArray = [[NSMutableArray alloc]init];
        _descriptors = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void)setBaby:(BabyBluetooth *)baby {
    if (baby && _baby != baby) {
        _baby = baby;
        // 清空数据
        [self clearData];
        // 配置ble委托
        [self babyCharacteristicDelegate];
    }
}

// 清空数据
- (void)clearData {
    [_descriptors removeAllObjects];
    [_readValueArray removeAllObjects];
}

// 读取Characteristic的详细信息
- (void)readCharacteristicDetails {
    //读取服务
    _baby.channel(_currChannel).characteristicDetails(self.currPeripheral,self.characteristic);
}

-(void)babyCharacteristicDelegate{
    
    __weak typeof(self)weakSelf = self;
    //设置读取characteristics的委托
    [_baby setBlockOnReadValueForCharacteristicAtChannel:_currChannel block:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        [weakSelf insertReadValues:characteristic];
        if (weakSelf.onReadValueForCharacteristic) {
            weakSelf.onReadValueForCharacteristic(peripheral, characteristic, error);
        }
    }];
    //设置发现characteristics的descriptors的委托
    [_baby setBlockOnDiscoverDescriptorsForCharacteristicAtChannel:_currChannel block:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        // NSLog(@"CharacteristicViewController===characteristic name:%@",characteristic.service.UUID);
        for (CBDescriptor *d in characteristic.descriptors) {
            // NSLog(@"CharacteristicViewController CBDescriptor name is :%@",d.UUID);
            [weakSelf insertDescriptor:d];
        }
    }];
    //设置读取Descriptor的委托
    [_baby setBlockOnReadValueForDescriptorsAtChannel:_currChannel block:^(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) {
        /*
        for (int i =0 ; i<_descriptors.count; i++) {
            if (_descriptors[i]==descriptor) {
                // NSString *valueStr = [[NSString alloc]initWithData:descriptor.value encoding:NSUTF8StringEncoding];
                NSString *valueStr = [NSString stringWithFormat:@"%@",descriptor.value];
            }
        }
        NSLog(@"CharacteristicViewController Descriptor name:%@ value is:%@",descriptor.characteristic.UUID, descriptor.value);
        */
        
        if (weakSelf.onReadValueForDescriptor) {
            weakSelf.onReadValueForDescriptor(peripheral, descriptor, error);
        }
    }];
    
    //设置写数据成功的block
    [_baby setBlockOnDidWriteValueForCharacteristicAtChannel:_currChannel block:^(CBCharacteristic *characteristic, NSError *error) {
        //NSLog(@"setBlockOnDidWriteValueForCharacteristicAtChannel characteristic:%@ and new value:%@",characteristic.UUID, characteristic.value);
        
        if (weakSelf.onDidWriteValueForCharacteristic) {
            weakSelf.onDidWriteValueForCharacteristic(characteristic, error);
        }
    }];
    
    //设置通知状态改变的block
    [_baby setBlockOnDidUpdateNotificationStateForCharacteristicAtChannel:_currChannel block:^(CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"uid:%@,isNotifying:%@",characteristic.UUID,characteristic.isNotifying?@"on":@"off");
    }];
}

//插入描述
-(void)insertDescriptor:(CBDescriptor *)descriptor{
    [_descriptors addObject:descriptor];
}
//插入读取的值
-(void)insertReadValues:(CBCharacteristic *)characteristics{
    [_readValueArray addObject:[NSString stringWithFormat:@"%@",characteristics.value]];
}

//写一个值
-(void)writeValue{
    // int i = 1;
    Byte b = 0X01;
    NSData *data = [NSData dataWithBytes:&b length:sizeof(b)];
    [self.currPeripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
}

//写一个值
- (void)writeDataWithString:(NSString *)str orInfoData:(NSData *)infoData {
    if (str == nil || str.length == 0)
    {
        if (self.currPeripheral && self.characteristic)
        {
            [self.currPeripheral writeValue:infoData forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
        }
        
    } else
    {
        NSData * data = [str dataUsingEncoding:NSUTF8StringEncoding];
        if (self.currPeripheral && self.characteristic)
        {
            [self.currPeripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
        }
    }
}
//订阅一个值
-(void)setNotifiy:(id)sender{
    
    __weak typeof(self)weakSelf = self;
    if (self.currPeripheral.state != CBPeripheralStateConnected) {
        NSLog(@"peripheral已经断开连接，请重新连接");
        return;
    }
    if (self.characteristic.properties & CBCharacteristicPropertyNotify ||  self.characteristic.properties & CBCharacteristicPropertyIndicate) {
        
        if (self.characteristic.isNotifying) {
            // @"通知"
            [_baby cancelNotify:self.currPeripheral characteristic:self.characteristic];
        } else {
            // @"取消通知"
            [weakSelf.currPeripheral setNotifyValue:YES forCharacteristic:self.characteristic];
            [_baby notify:self.currPeripheral characteristic:self.characteristic
                   block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
                       NSLog(@"notify block");
                       // NSLog(@"new value %@",characteristics.value);
                       [self insertReadValues:characteristics];
                   }];
        }
    } else {
        NSLog(@"这个characteristic没有notify的权限");
        return;
    }
}

#pragma mark -蓝牙打印
// 向蓝牙发送信息
- (BOOL)printPeripheral:(CBPeripheral *)peripheral dataWithString:(NSString *)str orInfoData:(NSData *)infoData forCharacteristic:(CBCharacteristic *)characteristic
{
    if (peripheral == nil || characteristic == nil)
    {
        valuePrint = NO;
    } else
    {
        valuePrint = YES;
        if (str == nil || str.length == 0)
        {
            if (peripheral && characteristic)
            {
                switch (characteristic.properties & 0x04)
                {
                    case CBCharacteristicPropertyWriteWithoutResponse:
                    {
                        [peripheral writeValue:infoData forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
                        break;
                        
                    }
                    default:
                    {
                        [peripheral writeValue:infoData forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
                        break;
                    }
                }
            }
            
        } else
        {
            NSData * data = [str dataUsingEncoding:NSUTF8StringEncoding];
            if (peripheral && characteristic)
            {
                switch (characteristic.properties & 0x04)
                {
                    case CBCharacteristicPropertyWriteWithoutResponse:
                    {
                        [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
                        break;
                        
                    }
                    default:
                    {
                        [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
                        break;
                    }
                }
            }
        }
    }
    return valuePrint;
}

@end
