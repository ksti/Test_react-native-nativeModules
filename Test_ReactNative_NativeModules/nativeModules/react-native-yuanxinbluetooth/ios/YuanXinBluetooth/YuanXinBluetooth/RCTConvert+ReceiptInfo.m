//
//  RCTConvert+ReceiptInfo.m
//  YuanXinBluetooth
//
//  Created by GJS on 2017/6/16.
//  Copyright © 2017年 GJS. All rights reserved.
//

#import "RCTConvert+ReceiptInfo.h"

@implementation RCTConvert (ReceiptInfo)

RCT_ARRAY_CONVERTER(ReceiptInfo)

+ (ReceiptInfo *)ReceiptInfo:(id)json {
    NSLog(@"gjs" " and " "%@" ": We love you!\n", @"GJS");
    
    ReceiptInfo *model = [ReceiptInfo new];
    NSDictionary *dict = [RCTConvert NSDictionary:json];
    model.key01 = dict[@"key01"] ?: @"";
    model.key02 = dict[@"key02"] ?: @"";
    model.key03 = dict[@"key03"] ?: @"";
    model.key04 = dict[@"key04"] ?: @"";

    return model;
}

@end
