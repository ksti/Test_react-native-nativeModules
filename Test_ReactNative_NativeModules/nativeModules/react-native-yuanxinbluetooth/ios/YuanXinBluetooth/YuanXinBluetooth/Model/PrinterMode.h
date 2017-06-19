//
//  PrinterMode.h
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
#import <Foundation/Foundation.h>
#import "MMPrinterManager.h"

//对齐方式
typedef NS_ENUM(UInt8, RCTPrinterAlignmentType) {
    RCTPrinterAlignmentTypeLeft = LeftAlignment,
    RCTPrinterAlignmentTypeMiddle = MiddleAlignment,
    RCTPrinterAlignmentTypeRight = RightAlignment,
};

//页模式下打印区域方向
typedef NS_ENUM(UInt8, RCTPrinterOrientation) {
    RCTPrinterOrientationLeftToRight = LeftToRight,
    RCTPrinterOrientationDownToUP = DownToUP,
    RCTPrinterOrientationRightToLeft = RightToLeft,
    RCTPrinterOrientationUpToDown = UpToDown,
};

//字符放大倍数
typedef NS_ENUM(UInt8, RCTPrinterCharScale) {
    RCTPrinterCharScale_1 = scale_1,
    RCTPrinterCharScale_2 = scale_2,
    RCTPrinterCharScale_3 = scale_3,
    RCTPrinterCharScale_4 = scale_4,
    RCTPrinterCharScale_5 = scale_5,
    RCTPrinterCharScale_6 = scale_6,
    RCTPrinterCharScale_7 = scale_7,
    RCTPrinterCharScale_8 = scale_8,
};

//选择字体
typedef NS_ENUM(UInt8, RCTPrinterCharFont) {
    RCTPrinterCharFontStandard = standardFont,
    RCTPrinterCharFontSmaller = smallerFont,
};

//切纸模式
typedef NS_ENUM(UInt8, RCTPrinterCutPaperModel) {
    RCTPrinterCutPaperModelFullCut = fullCut,
    RCTPrinterCutPaperModelHalfCut = halfCut,
    RCTPrinterCutPaperModelFeedPaperHalfCut = feedPaperHalfCut,
};

@interface RCTConvert(RCTPrinterMode)

+ (RCTPrinterAlignmentType)RCTPrinterAlignmentType:(id)json;
+ (RCTPrinterOrientation)RCTPrinterOrientation:(id)json;
+ (RCTPrinterCharScale)RCTPrinterCharScale:(id)json;
+ (RCTPrinterCharFont)RCTPrinterCharFont:(id)json;
+ (RCTPrinterCutPaperModel)RCTPrinterCutPaperModel:(id)json;

@end
