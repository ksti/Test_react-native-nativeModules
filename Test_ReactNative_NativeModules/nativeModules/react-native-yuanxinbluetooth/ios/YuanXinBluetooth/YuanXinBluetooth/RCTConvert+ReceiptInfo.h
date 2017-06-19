//
//  RCTConvert+ReceiptInfo.h
//  YuanXinBluetooth
//
//  Created by GJS on 2017/6/16.
//  Copyright © 2017年 GJS. All rights reserved.
//

#if __has_include(<React/RCTConvert.h>)
#import <React/RCTConvert.h>
#else
#import "RCTConvert.h"
#endif

#import "ReceiptInfo.h"

@interface RCTConvert (ReceiptInfo)

+ (NSArray<ReceiptInfo *> *)ReceiptInfoArray:(id)json;
+ (ReceiptInfo *)ReceiptInfo:(id)json;

@end
