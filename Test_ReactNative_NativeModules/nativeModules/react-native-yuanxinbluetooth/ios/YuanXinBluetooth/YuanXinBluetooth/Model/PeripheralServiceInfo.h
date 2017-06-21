//
//  PeripheralServiceInfo.h
//  YuanXinBluetooth
//
//  Created by GJS on 2017/6/5.
//  Copyright © 2017年 GJS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface PeripheralServiceInfo : NSObject

@property (nonatomic,strong) CBUUID *serviceUUID;
@property (nonatomic,strong) NSMutableArray *characteristics;

@end
