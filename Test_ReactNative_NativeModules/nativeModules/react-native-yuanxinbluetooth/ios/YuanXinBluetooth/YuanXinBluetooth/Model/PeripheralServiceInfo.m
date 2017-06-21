//
//  PeripheralServiceInfo.m
//  YuanXinBluetooth
//
//  Created by GJS on 2017/6/5.
//  Copyright © 2017年 GJS. All rights reserved.
//

#import "PeripheralServiceInfo.h"

@implementation PeripheralServiceInfo

- (instancetype)init{
    return [self initWithDict:nil];
}

- (instancetype)initWithDict:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _characteristics = [[NSMutableArray alloc]init];
        NSArray *arrayCharacteristics = [dict objectForKey:@"characteristics"];
        if ([arrayCharacteristics isKindOfClass:[NSArray class]]) {
            _characteristics = [arrayCharacteristics mutableCopy];
        }
        self.serviceUUID = [dict objectForKey:@"serviceUUID"];
    }
    return self;
}

@end
