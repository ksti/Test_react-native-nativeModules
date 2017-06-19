//
//  ReceiptInfo.h
//  YuanXinBluetooth
//
//  Created by GJS on 2017/6/16.
//  Copyright © 2017年 GJS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ReceiptInfo : NSObject

// 小票
// @{@"key01":@"汉堡", @"key02":@"10.00", @"key03":@"2", @"key04":@"20.00"}

/*
@[
  @{@"key01":@"汉堡", @"key02":@"10.00", @"key03":@"2", @"key04":@"20.00"},
  @{@"key01":@"炸鸡", @"key02":@"8.00", @"key03":@"1", @"key04":@"8.00"}
]
*/

@property (nonatomic, copy) NSString *key01;

@property (nonatomic, copy) NSString *key02;

@property (nonatomic, copy) NSString *key03;

@property (nonatomic, copy) NSString *key04;

@end
