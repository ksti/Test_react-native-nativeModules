//
//  PrinterMode.m
//  YuanXinBluetooth
//
//  Created by GJS on 2017/6/16.
//  Copyright © 2017年 GJS. All rights reserved.
//

#import "PrinterMode.h"

@implementation RCTConvert(RCTPrinterMode)

//对齐方式
RCT_ENUM_CONVERTER(RCTPrinterAlignmentType, (@{
                                     @"left": @(RCTPrinterAlignmentTypeLeft),
                                     @"right": @(RCTPrinterAlignmentTypeRight),
                                     @"middle": @(RCTPrinterAlignmentTypeMiddle),
                                     }), RCTPrinterAlignmentTypeLeft, integerValue)

//页模式下打印区域方向
RCT_ENUM_CONVERTER(RCTPrinterOrientation, (@{
                                               @"leftToRight": @(RCTPrinterOrientationLeftToRight),
                                               @"rightToLeft": @(RCTPrinterOrientationRightToLeft),
                                               @"upToDown": @(RCTPrinterOrientationUpToDown),
                                               @"downToUp": @(RCTPrinterOrientationDownToUP),
                                               }), RCTPrinterOrientationLeftToRight, integerValue)

//字符放大倍数
RCT_ENUM_CONVERTER(RCTPrinterCharScale, (@{
                                               @"scale1": @(RCTPrinterCharScale_1),
                                               @"scale2": @(RCTPrinterCharScale_2),
                                               @"scale3": @(RCTPrinterCharScale_3),
                                               @"scale4": @(RCTPrinterCharScale_4),
                                               @"scale5": @(RCTPrinterCharScale_5),
                                               @"scale6": @(RCTPrinterCharScale_6),
                                               @"scale7": @(RCTPrinterCharScale_7),
                                               @"scale8": @(RCTPrinterCharScale_8),
                                               }), RCTPrinterCharScale_1, integerValue)

//选择字体
RCT_ENUM_CONVERTER(RCTPrinterCharFont, (@{
                                               @"smaller": @(RCTPrinterCharFontSmaller),
                                               @"standard": @(RCTPrinterCharFontStandard),
                                               }), RCTPrinterCharFontStandard, integerValue)

//切纸模式
RCT_ENUM_CONVERTER(RCTPrinterCutPaperModel, (@{
                                               @"fullCut": @(RCTPrinterCutPaperModelFullCut),
                                               @"halfCut": @(RCTPrinterCutPaperModelHalfCut),
                                               @"feedPaperHalfCut": @(RCTPrinterCutPaperModelFeedPaperHalfCut),
                                               }), RCTPrinterCutPaperModelFullCut, integerValue)

@end
