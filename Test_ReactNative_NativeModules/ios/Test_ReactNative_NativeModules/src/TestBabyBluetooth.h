//
//  TestBabyBluetooth.h
//  Test_ReactNative_NativeModules
//
//  Created by GJS on 2017/5/12.
//  Copyright © 2017年 GJS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YuanXinBluetooth.h"
#import "BabyBluetooth.h"

#define Notification_DiscoverNewPeripheral @"DiscoverNewPeripheral"

@interface TestBabyBluetooth : NSObject

@property (nonatomic, readonly) BabyBluetooth *baby;

@end
