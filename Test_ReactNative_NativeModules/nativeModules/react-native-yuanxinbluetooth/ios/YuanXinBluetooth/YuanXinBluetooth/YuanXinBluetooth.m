//
//  YuanXinBluetooth.m
//  YuanXinBluetooth
//
//  Created by GJS on 2017/5/3.
//  Copyright © 2017年 GJS. All rights reserved.
//

#pragma mark ios 蓝牙逻辑整理
/**
 * ios 蓝牙逻辑整理
 * TODO: gjs->todo: 蓝牙逻辑再整理
 * 1.确定蓝牙打开
 * 1.先扫描，扫描到外设，然后才能确定连哪个外设
 * 1.如果想在扫描的过程中就获取设备的Mac地址 http://www.jianshu.com/p/1d6a8fc8134f
 *   在发现设备的回调里面：可以看到有一个 advertisementData ,这个字典类型的就是广播包，
 *   这里面会有一些设备的属性，比如设备的名字啊，服务啊等，但是都是被苹果限制了的，
 *   所以并不是你硬件工程师想广播什么都可以的。
 *   这个字典里有一个 key:kCBAdvDataManufacturerData
 *   只有这个key是可以放入信息的，所以叫硬件工程师将Mac地址写到这个字段里去，这样你就可以在发现设备的过程中得到Mac地址了~！
 * 2.再连接外设
 * 3.在连接后可以获取外设的Mac地址 http://blog.csdn.net/macpu/article/details/49805763
 *   虽然苹果官方的API没有获取Mac地址的方法，但是当我翻看蓝牙的文档的时候，
 *   我发现蓝牙有提供一个设备信息的service［service UUID：0x180A］,
 *   里面提供了两个characteristic：获取芯片的Mac地址（0x2A23 ）和获取软件的版本号（0x2A26）。
 *   (意思是新开两个通道，通过通道读取)
 * 3.根据外设UUID对应的string获取已配对的外设
 *   通过方法获取外设后可以直接连接外设，跳过扫描过程
 *   // BabyBluetooth
 *   - (CBPeripheral *)retrievePeripheralWithUUIDString:(NSString *)UUIDString;
 */

#import "YuanXinBluetooth.h"
#if __has_include(<React/RCTBridge.h>)
#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTUtils.h>
#import <React/RCTImageLoader.h>
#else
#import "RCTBridge.h"
#import "RCTConvert.h"
#import "RCTEventDispatcher.h"
#import "RCTUtils.h"
#import "RCTImageLoader.h"
#endif

#import "BabyBluetooth.h"
#import "BluetoothManager.h"
#import "PrinterMode.h"
#import "RCTConvert+ReceiptInfo.h"

#define kStartBtSuccess @"StartBtSuccess"
#define kStartBtError @"StartBtError"
#define kScanBtSuccess @"ScanBtSuccess"
#define kScanBtError @"ScanBtError"
#define kConnectBtSuccess @"ConnectBtSuccess"
#define kConnectBtError @"ConnectBtError"
#define kGetServicesSuccess @"GetServicesSuccess"
#define kGetServicesError @"GetServicesError"
#define kReadBtSuccess @"ReadBtSuccess"
#define kReadBtError @"ReadBtError"
#define kWriteBtSuccess @"WriteBtSuccess"
#define kWriteBtError @"WriteBtError"
#define kPrintReceiptSuccess @"PrintReceiptSuccess"
#define kPrintReceiptError @"PrintReceiptError"

@interface YuanXinBluetooth() {
    BluetoothManager *_bluetoothManager;
    BabyBluetooth *_initBaby; // 仅用来判断是不是第一次初始化。。
    NSMutableDictionary *_blockDict;
    CBManagerState _bluetoothState;
    NSArray *_peripheralsInfoArray;
    dispatch_source_t _scanTimer;
    BOOL _flagWithServices;
    NSArray *_scanServiceUUIDs;
    NSString *_connectUUIDString;
    NSMutableArray *_retrievedPeripherals;
}

@property (nonatomic, assign) BOOL hasListeners;

@property (nonatomic, copy) RCTPromiseResolveBlock successBlock;

@property (nonatomic, copy) RCTPromiseRejectBlock  errorBlock;

@end

@implementation YuanXinBluetooth

- (instancetype)init
{
    self = [super init];
    if (self) {
        __weak typeof (self) weakSelf = self;
        _blockDict = [NSMutableDictionary dictionary];
        _retrievedPeripherals = [NSMutableArray array];
        _bluetoothManager = [BluetoothManager shareInstance];
        _bluetoothState = _bluetoothManager.bluetoothState;
        __weak NSMutableDictionary *weakBlockDict = _blockDict;
        // 监听通知
        [[NSNotificationCenter defaultCenter] addObserverForName:Notification_DiscoverNewPeripheral object:nil queue:nil usingBlock:^(NSNotification * _Nonnull notification) {
            // 扫描到新外设
            [self handleDiscoverNewPeripheral:notification];
        }];
        // 设置代理回调
#pragma mark -主设备状态更新时回调
        _bluetoothManager.onCentralManagerDidUpdateState = ^(CBCentralManager *central) {
            /*!
             *  @enum CBManagerState
             *
             *  @discussion Represents the current state of a CBManager.
             *
             *  @constant CBManagerStateUnknown       State unknown, update imminent.
             *  @constant CBManagerStateResetting     The connection with the system service was momentarily lost, update imminent.
             *  @constant CBManagerStateUnsupported   The platform doesn't support the Bluetooth Low Energy Central/Client role.
             *  @constant CBManagerStateUnauthorized  The application is not authorized to use the Bluetooth Low Energy role.
             *  @constant CBManagerStatePoweredOff    Bluetooth is currently powered off.
             *  @constant CBManagerStatePoweredOn     Bluetooth is currently powered on and available to use.
             *
             */
            
            _bluetoothState = central.state;
            [weakSelf handleBluetoothCentralState:central];
        };
        /* 放到其他地方：具体连接的时候，交由 BluetoothPeripheralObject、BluetoothCharacteristicObject 处理
#pragma mark -主设备扫描到外设时回调
        _bluetoothManager.onConnectedAtChannel = ^(NSString *channel, CBCentralManager *central, CBPeripheral *peripheral) {
            //
            NSLog(@"连接到外设成功：%@", peripheral);
        };
#pragma mark -主设备读取外设数据回调
        _bluetoothManager.onReadValueForDescriptorAtChannel = ^(NSString *channel, CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) {
            //
        };
        _bluetoothManager.onReadValueForCharacteristicAtChannel = ^(NSString *channel, CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
            //
        };
        _bluetoothManager.onDidWriteValueForCharacteristicAtChannel = ^(NSString *channel, CBCharacteristic *characteristic, NSError *error) {
            //
        };
        */
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //停止扫描
    [_bluetoothManager.baby cancelScan];
}

RCT_EXPORT_MODULE(BlueToothModule);

/**
 * Override this method to return an array of supported event names. Attempting
 * to observe or send an event that isn't included in this list will result in
 * an error.
 */
- (NSArray<NSString *> *)supportedEvents
{
    return @[@"EventReminder"];
}

// 在添加第一个监听函数时触发
-(void)startObserving {
    _hasListeners = YES;
    // Set up any upstream listeners or background tasks as necessary
}

// Will be called when this module's last listener is removed, or on dealloc.
-(void)stopObserving {
    _hasListeners = NO;
    // Remove upstream listeners, stop unnecessary background tasks
}

- (void)testEmitter {
    //NSString *eventName = notification.userInfo[@"name"];
    NSString *eventName = @"test name";
    if (_hasListeners) { // Only send events if anyone is listening
        [self sendEventWithName:@"EventReminder" body:@{@"name": eventName}];
    }
}

#pragma mark 处理蓝牙状态更新

- (void)handleBluetoothCentralState:(CBCentralManager *)central {
    switch (central.state) {
        case CBManagerStateUnsupported:
            // @"该设备不支持蓝牙功能,请检查系统设置";
            break;
        case CBManagerStateUnauthorized:
            // @"该设备蓝牙未授权,请检查系统设置";
            break;
        case CBManagerStatePoweredOff:
            // @"该设备尚未打开蓝牙,请在设置中打开";
            break;
        case CBManagerStatePoweredOn:
            // @"蓝牙已经成功开启";
        {
            __block RCTPromiseResolveBlock successBlockStartBt = _blockDict[kStartBtSuccess];
            if (successBlockStartBt) {
                // 如果是还存在开启蓝牙的等待block，则回调蓝牙开启成功
                [self callbackStartBt];
            }
            __block RCTPromiseResolveBlock successBlockScanBt = _blockDict[kScanBtSuccess];
            if (successBlockScanBt) {
                // 如果是还存在扫描外设的等待block，则扫描外设
                [self scanServices:_scanServiceUUIDs];
            }
            __block RCTPromiseResolveBlock successBlockConnectBt = _blockDict[kConnectBtSuccess];
            if (successBlockConnectBt) {
                // 如果是还存在连接外设的等待block，则扫描外设
                [self connectPeripheralWithIdentifier:_connectUUIDString];
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark 获取蓝牙状态

/**
 *  获取蓝牙状态
 */
RCT_REMAP_METHOD(getBtState,
                 getBtStateResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
    NSString *code = [[NSNumber numberWithInt:_bluetoothState] stringValue];
    NSString *message = @"未知状态";
    switch (_bluetoothState) {
        case CBManagerStateUnsupported:
            message = @"该设备不支持蓝牙功能,请检查系统设置";
            break;
        case CBManagerStateUnauthorized:
            message = @"该设备蓝牙未授权,请检查系统设置";
            break;
        case CBManagerStatePoweredOff:
            message = @"该设备尚未打开蓝牙,请在设置中打开";
            break;
        case CBManagerStatePoweredOn:
            message = @"蓝牙已经成功开启";
            break;
        default:
            break;
    }
    
    if(resolve){
        resolve(@{@"code": code,
                  @"message": message});
    }
}

#pragma mark 启动蓝牙
/**
 *  启动蓝牙
 */
RCT_REMAP_METHOD(startBt,
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
    if(resolve){
        _blockDict[kStartBtSuccess] = [resolve copy];
    }
    if(reject){
        _blockDict[kStartBtError] = [reject copy];
    }
    
    [self startBluetooth];
}

- (void)startBluetooth {
    if (_bluetoothState == CBManagerStatePoweredOn) {
        [self callbackStartBt];
        return;
    }
    [self firstStartBluetoothWhenReject:^(NSString *code, NSString *message, NSError *error) {
        //
        __block RCTPromiseRejectBlock errorBlock = _blockDict[kStartBtError];
        if (errorBlock) {
            errorBlock(code, message, error);
        }
        
        // 回调完删除
        [_blockDict removeObjectForKey:kStartBtSuccess];
        [_blockDict removeObjectForKey:kStartBtError];
        errorBlock = nil;
    }];
}

// 启动蓝牙，包括处理第一次启动的情形，debug模式下reload时即使是初始化蓝牙也没有系统弹框，杀掉app倒是可以
- (void)firstStartBluetoothWhenReject:(void (^)(NSString *code, NSString *message, NSError *error))reject {
    //BabyBluetooth *initBaby = _bluetoothManager.baby; // 懒加载
    BOOL firstInitBaby = _initBaby == nil;
    if (!_bluetoothManager.baby) { // 懒加载
        if (reject) {
            reject(@"-1", @"蓝牙初始化失败！", nil);
        }
        return;
    }
    if (firstInitBaby) {
        _initBaby = _bluetoothManager.baby;
        // 等待5秒，
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
            if (_bluetoothState == CBManagerStatePoweredOff) {
                if (reject) {
                    reject(@"-1", @"该设备尚未打开蓝牙,请在设置中打开", nil);
                }
            }
        });
    } else {
        [self startBluetoothWhenReject:reject];
    }
}

// 启动蓝牙，只负责启动失败时候的处理，不处理已开启的情况，已开启另行处理
- (void)startBluetoothWhenReject:(void (^)(NSString *code, NSString *message, NSError *error))reject {
    //BabyBluetooth *initBaby = _bluetoothManager.baby; // 懒加载
    if (!_bluetoothManager.baby) { // 懒加载
        if (reject) {
            reject(@"-1", @"蓝牙初始化失败！", nil);
        }
        return;
    }
    
    /** 其实不必照顾这种情况，因为上面懒加载的时候，第一次初始化就会弹出设置框，
      * 如果这时再弹显得有点多余，不过系统弹框没有自定义事件，
      * 目前不知道第一次怎么不让弹系统框
      */
    if (_bluetoothState == CBManagerStateUnknown) {
        // 等待1秒，没找到好办法，因为初始状态是 CBManagerStateUnknown
        // 理论上，蓝牙状态势必会更新的
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
            if (_bluetoothState == CBManagerStatePoweredOff) {
                [self showAlertToSetBtWithReject:^(NSString *code, NSString *message, NSError *error) {
                    if (reject) {
                        reject(code, message, error);
                    }
                }];
            }
        });
    } else {
        if (_bluetoothState == CBManagerStatePoweredOff) {
            [self showAlertToSetBtWithReject:^(NSString *code, NSString *message, NSError *error) {
                if (reject) {
                    reject(code, message, error);
                }
            }];
        }
    }
}

- (void)callbackStartBt {
    //__weak NSMutableDictionary *weakBlockDict = _blockDict;
    //__block RCTPromiseResolveBlock successBlock = weakBlockDict[@"startBtSuccess"];
    //__block RCTPromiseRejectBlock errorBlock = weakBlockDict[@"startBtError"];
    
    __block RCTPromiseResolveBlock successBlock = _blockDict[kStartBtSuccess];
    __block RCTPromiseRejectBlock errorBlock = _blockDict[kStartBtError];
    
    //
    NSString *code = [[NSNumber numberWithInt:_bluetoothState] stringValue];
    NSString *message = @"未知状态";
    BOOL success = NO;
    switch (_bluetoothState) {
        case CBManagerStateUnsupported:
            message = @"该设备不支持蓝牙功能,请检查系统设置";
            break;
        case CBManagerStateUnauthorized:
            message = @"该设备蓝牙未授权,请检查系统设置";
            break;
        case CBManagerStatePoweredOff:
            message = @"该设备尚未打开蓝牙,请在设置中打开";
            break;
        case CBManagerStatePoweredOn:
            message = @"蓝牙已经成功开启";
            success = YES;
            break;
        default:
            break;
    }
    
    if (success) {
        if (successBlock) {
            successBlock(@{@"code": code,
                           @"message": message});
        }
    } else {
        if (errorBlock) {
            errorBlock(code, message, nil);
        }
    }
    
    // 回调完删除
    [_blockDict removeObjectForKey:kStartBtSuccess];
    [_blockDict removeObjectForKey:kStartBtError];
    successBlock = nil;
    errorBlock = nil;
}

#pragma mark 扫描外设

///* 后面的 RCT_EXPORT_METHOD(ScanBt:(id)json 会覆盖前面的
RCT_REMAP_METHOD(ScanBt,
                 ScanBtResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
    [self scanServices:nil resolver:resolve rejecter:reject];
}
//*/

RCT_EXPORT_METHOD(ScanBt:(id)json
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSArray *scanServices = [RCTConvert NSArray:json];
    [self scanServices:scanServices resolver:resolve rejecter:reject];
}

RCT_EXPORT_METHOD(scanServices:(id)json
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSArray *serviceUUIDs = [RCTConvert NSArray:json];
    NSMutableArray *mServiceUUIDs = [NSMutableArray arrayWithCapacity:serviceUUIDs.count];
    for (NSString *serviceUUIDString in serviceUUIDs) {
        CBUUID *serviceUUID = [CBUUID UUIDWithString:serviceUUIDString];
        [mServiceUUIDs addObject:serviceUUID];
    }
    
    _scanServiceUUIDs = [mServiceUUIDs copy]; // 保存要扫描特定的服务
    if(resolve){
        _blockDict[kScanBtSuccess] = [resolve copy];
    }
    if(reject){
        _blockDict[kScanBtError] = [reject copy];
    }
    
    if (_bluetoothState != CBManagerStatePoweredOn) {
        [self firstStartBluetoothWhenReject:^(NSString *code, NSString *message, NSError *error) {
            if (reject) {
                reject(code, message, error);
            }
            
            // 回调完删除
            [_blockDict removeObjectForKey:kScanBtSuccess];
            [_blockDict removeObjectForKey:kScanBtError];
        }];
    } else {
        [self scanServices:_scanServiceUUIDs];
    }
}

- (void)scanServices:(nullable NSArray<CBUUID *> *)serviceUUIDs {
    //
    _flagWithServices = serviceUUIDs.count > 0;
    [self scanWithServices:serviceUUIDs discoverWithServices:nil discoverWithCharacteristics:nil];
    
    float afterSeconds = 60; // 默认1分钟超时，回调
    // after 3 sec, for test.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, afterSeconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        [self callbackScanBt];
    });
}

// 扫描
- (void)scanBluetooth {
    [self scanBluetoothWithTimeout:(60 * 3)]; // 扫描最多3分钟
}

- (void)scanBluetoothWithTimeout:(float)afterSeconds {
    //停止之前的连接
    //[_bluetoothManager.baby cancelAllPeripheralsConnection];
    //设置委托后直接可以使用，无需等待CBCentralManagerStatePoweredOn状态。
    _bluetoothManager.baby.scanForPeripherals().begin();
    
    [self startScanTimerWithTimeout:afterSeconds];
}

- (void)scanWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs discoverWithServices:(nullable NSArray<CBUUID *> *)discoverServiceUUIDs discoverWithCharacteristics:(nullable NSArray<CBUUID *> *)discoverCharacteristics {
    // 先清除缓存数据
    [_bluetoothManager clearPeripheralsArray];
    // 设置可选项
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    NSDictionary *connectPeripheralWithOptions = @{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES};
    [_bluetoothManager setBabyOptionsWithScanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:connectPeripheralWithOptions scanForPeripheralsWithServices:serviceUUIDs discoverWithServices:discoverServiceUUIDs discoverWithCharacteristics:discoverCharacteristics];
    [self scanBluetooth];
}

- (void)handleDiscoverNewPeripheral:(NSNotification *)notification {
    // 扫描到新外设
    NSArray *peripheralDataArray = (NSArray *)notification.object;
    _peripheralsInfoArray = [self getPeripheralsInfo:peripheralDataArray];
    NSLog(@"%@", notification.name);
    NSDictionary *pInfo = [peripheralDataArray lastObject];
    CBPeripheral *p = pInfo[@"peripheral"];
    if (_flagWithServices) {
        [self callbackScanBt];
    }
}

- (void)callbackScanBt {
    //停止扫描
    [_bluetoothManager.baby cancelScan];
    [self invalidateScanTimer];
    // 超时时间到(默认1分钟)，回调
    __block RCTPromiseResolveBlock successBlock = _blockDict[kScanBtSuccess];
    __block RCTPromiseRejectBlock errorBlock = _blockDict[kScanBtError];
    if (_peripheralsInfoArray.count > 0) {
        if (successBlock) {
            successBlock(_peripheralsInfoArray);
            successBlock = nil;
        }
    } else {
        if (errorBlock) {
            errorBlock(@"-1", @"未扫描到外设请检查外设是否开启并重新尝试", nil);
            errorBlock = nil;
        }
    }
    
    // 回调完删除
    [_blockDict removeObjectForKey:kScanBtSuccess];
    [_blockDict removeObjectForKey:kScanBtError];
    successBlock = nil;
    errorBlock = nil;
}

- (void)showAlertToSetBtWithReject:(RCTPromiseRejectBlock)reject {
    __block RCTPromiseRejectBlock errorBlock = reject;
    // 弹出提示框
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"您的应用想要打开蓝牙" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"拒绝" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 拒绝不作任何处理
        // 有回调时回调
        if (errorBlock) {
            NSString *code = [[NSNumber numberWithInt:_bluetoothState] stringValue];
            errorBlock(code, @"该设备尚未打开蓝牙,请在设置中打开", nil);
        }
    }];
    
    UIAlertAction *otherAction = [UIAlertAction actionWithTitle:@"允许" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 允许用户打开蓝牙就会跳转到蓝牙设置页面
        // 关于系统的各个服务设置的url: http://blog.csdn.net/ouyangtianhan/article/details/22041121
        //[self openURLWithString:@"prefs:root=Bluetooth"];
        [self openURLWithString:@"App-Prefs:root=Bluetooth"];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:otherAction];
    
    UIViewController *currentVC = [self getCurrentVC];
    if (currentVC) {
        [currentVC presentViewController:alertController animated:YES completion:nil];
    }
}

#pragma mark 配对连接

RCT_EXPORT_METHOD(connBtDev:(id)json
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
    [self connectPeripheral:json resolver:resolve rejecter:reject];
}

RCT_EXPORT_METHOD(connectPeripheral:(id)json
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSDictionary *options = [RCTConvert NSDictionary:json];
    NSString *identifier = nil;
    if ([options isKindOfClass:[NSDictionary class]]) {
        identifier = options[@"peripheral"];
    }
    [self connectPeripheralWithIdentifier:identifier resolver:resolve rejecter:reject];
}

RCT_EXPORT_METHOD(connectPeripheralWithIdentifier:(NSString *)UUIDString
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    _connectUUIDString = UUIDString;
    if(resolve){
        _blockDict[kConnectBtSuccess] = [resolve copy];
    }
    if(reject){
        _blockDict[kConnectBtError] = [reject copy];
    }
    
    if (_bluetoothState != CBManagerStatePoweredOn) {
        [self firstStartBluetoothWhenReject:^(NSString *code, NSString *message, NSError *error) {
            if (reject) {
                reject(code, message, error);
            }
            
            // 回调完删除
            [_blockDict removeObjectForKey:kConnectBtSuccess];
            [_blockDict removeObjectForKey:kConnectBtError];
        }];
    } else {
        [self connectPeripheralWithIdentifier:UUIDString];
    }
}

- (void)connectPeripheralWithIdentifier:(NSString *)UUIDString {
    // TODO: gjs->todo: 连接指定设备
    //[_bluetoothManager retrievePeripheralWithUUIDString:UUIDString];
    CBPeripheral *peripheral = [_bluetoothManager findPeripheralByIdentifier:UUIDString];
    if (peripheral == nil) {
        peripheral = [_bluetoothManager retrievePeripheralWithUUIDString:UUIDString];
    }
    if (peripheral) {
        // [CoreBluetooth] API MISUSE: Cancelling connection for unused peripheral <CBPeripheral: 0x1702ebb00, identifier = 67D824DD-EB3F-4C9F-8F27-DACDE124D71E, name = G_G, state = connecting>, Did you forget to keep a reference to it?
        [self insertPeripheral:peripheral]; // 要先保持引用 peripheral，不然会立即释放
        [self connectPeripheral:peripheral];
    } else {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"无法连接到指定的外设", NSLocalizedDescriptionKey, @"失败原因：可能是找不到指定的外设", NSLocalizedFailureReasonErrorKey, @"恢复建议：可尝试先扫描再连接扫描到的指定外设",NSLocalizedRecoverySuggestionErrorKey,nil];
        
        NSError *error = [[NSError alloc] initWithDomain:CBErrorDomain code:CBErrorNotConnected userInfo:userInfo];//此处code是CBErrorNotConnected即3，代表未连接。userinfo传userinfo 查看自定义打印。userinfo传nil，查看本地化描述。
        [self callbackConnectBt:NO peripheral:peripheral error:error];
    }
}

- (void)connectPeripheral:(CBPeripheral *)currPeripheral {
    __weak typeof (self) weakSelf = self;
    // 停止扫描
    [_bluetoothManager.baby cancelScan];
    // 连接配对
    _bluetoothManager.onConnectedAtChannel = ^(NSString *channel, CBCentralManager *central, CBPeripheral *peripheral) {
        //
        [weakSelf callbackConnectBt:YES peripheral:peripheral error:nil];
    };
    _bluetoothManager.onFailToConnectAtChannel = ^(NSString *channel, CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        //
        [weakSelf callbackConnectBt:NO peripheral:peripheral error:error];
    };
    [_bluetoothManager connectPeripheral:currPeripheral];
    [_bluetoothManager AutoReconnect:currPeripheral]; // 自动重连
}

- (void)callbackConnectBt:(BOOL)success peripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    __block RCTPromiseResolveBlock successBlock = _blockDict[kConnectBtSuccess];
    __block RCTPromiseRejectBlock errorBlock = _blockDict[kConnectBtError];
    
    NSString *identifier = [peripheral.identifier UUIDString];
    
    if (success) {
        if (successBlock) {
            successBlock(@{@"peripheral": identifier,
                           @"name": peripheral.name});
        }
    } else {
        if (errorBlock) {
            errorBlock([NSString stringWithFormat:@"%zd", error.code], error.localizedDescription, nil);
        }
    }
    
    // 回调完删除
    [_blockDict removeObjectForKey:kConnectBtSuccess];
    [_blockDict removeObjectForKey:kConnectBtError];
    successBlock = nil;
    errorBlock = nil;
}

#pragma mark 获取外设提供的服务

RCT_EXPORT_METHOD(getPeripheralServices:(NSString *)peripheralUUIDString
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    if(resolve){
        _blockDict[kGetServicesSuccess] = [resolve copy];
    }
    if(reject){
        _blockDict[kGetServicesError] = [reject copy];
    }
    
    if (_bluetoothState != CBManagerStatePoweredOn) {
        if (reject) {
            reject(@"-1", @"该设备尚未打开蓝牙,请在设置中打开", nil);
        }
        
        // 回调完删除
        [_blockDict removeObjectForKey:kGetServicesSuccess];
        [_blockDict removeObjectForKey:kGetServicesError];
    } else {
        [self callbackGetServices];
    }
}

- (void)callbackGetServices {
    
    __block RCTPromiseResolveBlock successBlock = _blockDict[kGetServicesSuccess];
    __block RCTPromiseRejectBlock errorBlock = _blockDict[kGetServicesError];
    
    NSArray *services = [self getPeripheralServices];
    
    if (successBlock) {
        successBlock(@{@"result": services});
    }
    
    // 回调完删除
    [_blockDict removeObjectForKey:kGetServicesSuccess];
    [_blockDict removeObjectForKey:kGetServicesError];
    successBlock = nil;
    errorBlock = nil;
}

#pragma mark 读写操作
#pragma mark -读取外设数据

RCT_EXPORT_METHOD(readBtData:(id)json
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    [self readPeripheral:json resolver:resolve rejecter:reject];
}

RCT_EXPORT_METHOD(readPeripheral:(id)json
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSDictionary *options = [RCTConvert NSDictionary:json];
    NSString *peripheralUUIDString = nil;
    NSString *characteristicUUIDString = nil;
    if ([options isKindOfClass:[NSDictionary class]]) {
        peripheralUUIDString = options[@"peripheral"];
        characteristicUUIDString = options[@"characteristic"];
    }
    [self readPeripheralIdentifier:peripheralUUIDString characteristicUUIDString:characteristicUUIDString resolver:resolve rejecter:reject];
}

RCT_EXPORT_METHOD(readPeripheralIdentifier:(NSString *)peripheralUUIDString
                  characteristicUUIDString:(NSString *)characteristicUUIDString
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    if(resolve){
        _blockDict[kReadBtSuccess] = [resolve copy];
    }
    if(reject){
        _blockDict[kReadBtError] = [reject copy];
    }
    
    if (_bluetoothState != CBManagerStatePoweredOn) {
        if (reject) {
            reject(@"-1", @"该设备尚未打开蓝牙,请在设置中打开", nil);
        }
        
        // 回调完删除
        [_blockDict removeObjectForKey:kReadBtSuccess];
        [_blockDict removeObjectForKey:kReadBtError];
    } else {
        // TODO: gjs->todo: callbackReadBt
        [self readPeripheralWithIdentifier:peripheralUUIDString characteristicUUIDString:characteristicUUIDString];
    }
}

- (void)callbackReadBt:(BOOL)success peripheral:(CBPeripheral *)peripheral characteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    __block RCTPromiseResolveBlock successBlock = _blockDict[kReadBtSuccess];
    __block RCTPromiseRejectBlock errorBlock = _blockDict[kReadBtError];
    
    NSString *identifier = [peripheral.identifier UUIDString];
    
    if (success) {
        if (successBlock) {
            successBlock(@{@"peripheral": identifier,
                           @"characteristic": characteristic.UUID.UUIDString,
                           @"value": [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]});
        }
    } else {
        if (errorBlock) {
            errorBlock([NSString stringWithFormat:@"%zd", error.code], error.localizedDescription, nil);
        }
    }
    
    // 回调完删除
    [_blockDict removeObjectForKey:kReadBtSuccess];
    [_blockDict removeObjectForKey:kReadBtError];
    successBlock = nil;
    errorBlock = nil;
}

// 读操作
- (void)readPeripheralWithIdentifier:(NSString *)peripheralUUIDString characteristicUUIDString:(NSString *)characteristicUUIDString {
    //
    CBPeripheral *peripheral = [_bluetoothManager findPeripheralByIdentifier:peripheralUUIDString];
    [self readPeripheral:peripheral characteristicDetails:[_bluetoothManager findCharacteristicByUUIDString:characteristicUUIDString]];
}

// 读操作
- (void)readPeripheral:(CBPeripheral *)aPeripheral characteristicDetails:(CBCharacteristic *)aCharacteristic {
    __weak typeof (self) weakSelf = self;
    // 停止扫描
    [_bluetoothManager.baby cancelScan];
    _bluetoothManager.onReadValueForCharacteristicAtChannel = ^(NSString *channel, CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        //
        NSLog(@"onReadValueForCharacteristic:%@", characteristic);
        if (error) {
            [weakSelf callbackReadBt:NO peripheral:peripheral characteristic:characteristic error:error];
        } else {
            [weakSelf callbackReadBt:YES peripheral:peripheral characteristic:characteristic error:error];
        }
    };
    _bluetoothManager.onReadValueForDescriptorAtChannel = ^(NSString *channel, CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) {
        //
        NSLog(@"onReadValueForDescriptor:%@", descriptor);
    };
    //
    [_bluetoothManager readPeripheral:aPeripheral characteristicDetails:aCharacteristic];
}

#pragma mark -向蓝牙发送消息

RCT_EXPORT_METHOD(writeBtData:(id)json
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    [self writePeripheral:json resolver:resolve rejecter:reject];
}

RCT_EXPORT_METHOD(writePeripheral:(id)json
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSDictionary *options = [RCTConvert NSDictionary:json];
    NSString *peripheralUUIDString = nil;
    NSString *characteristicUUIDString = nil;
    NSString *dataStr = nil;
    if ([options isKindOfClass:[NSDictionary class]]) {
        peripheralUUIDString = options[@"peripheral"];
        characteristicUUIDString = options[@"characteristic"];
        dataStr = options[@"data"];
    }
    [self writePeripheralIdentifier:peripheralUUIDString forCharacteristicUUIDString:characteristicUUIDString dataWithString:dataStr resolver:resolve rejecter:reject];
}

RCT_EXPORT_METHOD(writePeripheralIdentifier:(NSString *)peripheralUUIDString
                  forCharacteristicUUIDString:(NSString *)characteristicUUIDString
                  dataWithString:(NSString *)str
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    if(resolve){
        _blockDict[kWriteBtSuccess] = [resolve copy];
    }
    if(reject){
        _blockDict[kWriteBtError] = [reject copy];
    }
    
    if (_bluetoothState != CBManagerStatePoweredOn) {
        if (reject) {
            reject(@"-1", @"该设备尚未打开蓝牙,请在设置中打开", nil);
        }
        
        // 回调完删除
        [_blockDict removeObjectForKey:kWriteBtSuccess];
        [_blockDict removeObjectForKey:kWriteBtError];
    } else {
        // TODO: gjs->todo: callbackWriteBt
        [self writePeripheralWithIdentifier:peripheralUUIDString dataWithString:str orInfoData:nil forCharacteristicUUIDString:characteristicUUIDString];
    }
}

- (void)callbackWriteBt:(BOOL)success peripheral:(CBPeripheral *)peripheral characteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    __block RCTPromiseResolveBlock successBlock = _blockDict[kWriteBtSuccess];
    __block RCTPromiseRejectBlock errorBlock = _blockDict[kWriteBtError];
    
    NSString *identifier = [peripheral.identifier UUIDString];
    
    if (success) {
        if (successBlock) {
            successBlock(@{@"peripheral": identifier,
                           @"characteristic": characteristic.UUID.UUIDString,
                           });
        }
    } else {
        if (errorBlock) {
            errorBlock([NSString stringWithFormat:@"%zd", error.code], error.localizedDescription, nil);
        }
    }
    
    // 回调完删除
    [_blockDict removeObjectForKey:kWriteBtSuccess];
    [_blockDict removeObjectForKey:kWriteBtError];
    successBlock = nil;
    errorBlock = nil;
}

// 写操作
- (void)writePeripheralWithIdentifier:(NSString *)peripheralUUIDString dataWithString:(NSString *)str orInfoData:(NSData *)infoData forCharacteristicUUIDString:(NSString *)characteristicUUIDString {
    //
    CBPeripheral *peripheral = [_bluetoothManager findPeripheralByIdentifier:peripheralUUIDString];
    [self writePeripheral:peripheral dataWithString:str orInfoData:infoData forCharacteristicUUIDString:characteristicUUIDString];
}

// 写操作
- (void)writePeripheral:(CBPeripheral *)aPeripheral dataWithString:(NSString *)str orInfoData:(NSData *)infoData forCharacteristicUUIDString:(NSString *)characteristicUUIDString {
    [self writePeripheral:aPeripheral dataWithString:str orInfoData:infoData forCharacteristic:[_bluetoothManager findCharacteristicByUUIDString:characteristicUUIDString]];
}

// 写操作
- (void)writePeripheral:(CBPeripheral *)aPeripheral dataWithString:(NSString *)str orInfoData:(NSData *)infoData forCharacteristic:(CBCharacteristic *)aCharacteristic {
    __weak typeof (self) weakSelf = self;
    // 停止扫描
    [_bluetoothManager.baby cancelScan];
    _bluetoothManager.onDidWriteValueForCharacteristicAtChannel = ^(NSString *channel, CBCharacteristic *characteristic, NSError *error) {
        //
        if (error) {
            [weakSelf callbackWriteBt:NO peripheral:aPeripheral characteristic:characteristic error:error];
        } else {
            [weakSelf callbackWriteBt:YES peripheral:aPeripheral characteristic:characteristic error:error];
        }
    };
    //
    [_bluetoothManager writePeripheral:aPeripheral dataWithString:str orInfoData:infoData forCharacteristic:aCharacteristic];
}

#pragma mark -蓝牙打印(小票)

RCT_REMAP_METHOD(printReceiptClear,
                  printClearResolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    [_bluetoothManager printerClearData];
    [_bluetoothManager printerBasicSetting];
    if (resolve) {
        resolve(@YES);
    }
}

RCT_EXPORT_METHOD(printReceiptToPeripheral:(id)json
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    if(resolve){
        _blockDict[kPrintReceiptSuccess] = [resolve copy];
    }
    if(reject){
        _blockDict[kPrintReceiptError] = [reject copy];
    }
    
    if (_bluetoothState != CBManagerStatePoweredOn) {
        if (reject) {
            reject(@"-1", @"该设备尚未打开蓝牙,请在设置中打开", nil);
        }
        
        // 回调完删除
        [_blockDict removeObjectForKey:kPrintReceiptSuccess];
        [_blockDict removeObjectForKey:kPrintReceiptError];
    } else {
        NSDictionary *options = [RCTConvert NSDictionary:json];
        NSString *peripheralUUIDString = nil;
        NSString *characteristicUUIDString = nil;
        if ([options isKindOfClass:[NSDictionary class]]) {
            peripheralUUIDString = options[@"peripheral"];
            characteristicUUIDString = options[@"characteristic"];
        }
        CBPeripheral *peripheral = [_bluetoothManager findPeripheralByIdentifier:peripheralUUIDString];
        CBCharacteristic *characteristic = [_bluetoothManager findCharacteristicByUUIDString:characteristicUUIDString];
        
        // TODO: gjs->todo: callbackPrintReceipt
        [self printReceiptToPeripheral:peripheral forCharacteristic:characteristic];
    }
}

- (void)callbackPrintReceipt:(BOOL)success peripheral:(CBPeripheral *)peripheral characteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    __block RCTPromiseResolveBlock successBlock = _blockDict[kPrintReceiptSuccess];
    __block RCTPromiseRejectBlock errorBlock = _blockDict[kPrintReceiptError];
    
    NSString *identifier = [peripheral.identifier UUIDString];
    
    if (success) {
        if (successBlock) {
            successBlock(@{@"peripheral": identifier,
                           @"characteristic": characteristic.UUID.UUIDString,
                           });
        }
    } else {
        if (errorBlock) {
            errorBlock([NSString stringWithFormat:@"%zd", error.code], error.localizedDescription, nil);
        }
    }
    
    // 回调完删除
    [_blockDict removeObjectForKey:kPrintReceiptSuccess];
    [_blockDict removeObjectForKey:kPrintReceiptError];
    successBlock = nil;
    errorBlock = nil;
}

- (void)printReceiptToPeripheral:(CBPeripheral *)aPeripheral forCharacteristic:(CBCharacteristic *)aCharacteristic {
    __weak typeof (self) weakSelf = self;
    // 停止扫描
    [_bluetoothManager.baby cancelScan];
    _bluetoothManager.onDidWriteValueForCharacteristicAtChannel = ^(NSString *channel, CBCharacteristic *characteristic, NSError *error) {
        //
        if (error) {
            [weakSelf callbackPrintReceipt:NO peripheral:aPeripheral characteristic:characteristic error:error];
        } else {
            [weakSelf callbackPrintReceipt:YES peripheral:aPeripheral characteristic:characteristic error:error];
        }
    };
    
    [_bluetoothManager receiptPrint:aPeripheral forCharacteristic:aCharacteristic];
}

//写入单行文字
RCT_EXPORT_METHOD(printerReceiptWriteTitle:(id)title
                  options:(id)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSDictionary *optionsDict = [RCTConvert NSDictionary:options];
    RCTPrinterCharScale charScale = [RCTConvert RCTPrinterCharScale:optionsDict[@"charScale"]];
    RCTPrinterAlignmentType alignType = [RCTConvert RCTPrinterAlignmentType:optionsDict[@"alignType"]];
    [_bluetoothManager printerWriteData_title:title Scale:(kCharScale)charScale Type:(kAlignmentType)alignType];
    if (resolve) {
        resolve(@YES);
    }
}
//打印图片
RCT_EXPORT_METHOD(printerReceiptWriteQrImageStr:(id)qrImageStr
                  options:(id)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSDictionary *optionsDict = [RCTConvert NSDictionary:options];
    RCTPrinterAlignmentType alignType = [RCTConvert RCTPrinterAlignmentType:optionsDict[@"alignType"]];
    CGFloat maxWidth = [RCTConvert CGFloat:optionsDict[@"maxWidth"]];
    if (maxWidth <= 0) {
        maxWidth = 300;
    }
    [_bluetoothManager printerWriteData_qrImageStr:qrImageStr alignment:(kAlignmentType)alignType maxWidth:maxWidth];
    if (resolve) {
        resolve(@YES);
    }
}
//写入多行文字
RCT_EXPORT_METHOD(printerReceiptWriteItems:(id)items
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    [_bluetoothManager printerWriteData_items:items];
    if (resolve) {
        resolve(@YES);
    }
}
//打印分割线
RCT_REMAP_METHOD(printerReceiptWriteLine,
                  printerWriteLineResolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    [_bluetoothManager printerWriteData_line];
    if (resolve) {
        resolve(@YES);
    }
}
//条目,菜单,有间隔,如:
//  炸鸡排     2      12.50      25.00
RCT_EXPORT_METHOD(printerReceiptWriteContent:(NSArray<ReceiptInfo *> *)items
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    [_bluetoothManager printerWriteData_content:items]; // 会自动转换 [RCTConvert ReceiptInfoArray:items]
    if (resolve) {
        resolve(@YES);
    }
}

#pragma mark - business
//
- (NSArray *)getPeripheralsInfo:(NSArray *)peripheralDataArray {
    NSMutableArray *mArray = [peripheralDataArray mutableCopy];
    for (NSUInteger index = 0; index < mArray.count; index ++) {
        NSDictionary *dataInfo = mArray[index];
        CBPeripheral *peripheral = dataInfo[@"peripheral"];
        if ([peripheral isKindOfClass:[CBPeripheral class]]) {
            NSMutableDictionary *mDict = [NSMutableDictionary dictionaryWithDictionary:dataInfo];
            [mDict setObject:[peripheral.identifier UUIDString] forKey:@"peripheral"];
            mArray[index] = mDict;
        }
    }
    return [mArray copy];
}

- (NSArray *)getPeripheralServices {
    NSMutableArray *mArray = [NSMutableArray array];
    NSArray *discoveredServices = [_bluetoothManager getPeripheralServices];
    for (PeripheralInfo *info in discoveredServices) {
        NSArray *discoveredCharacteristics = info.characteristics;
        NSMutableArray *mCharacteristicsArray = [NSMutableArray array];
        for (CBCharacteristic *cha in discoveredCharacteristics) {
            [mCharacteristicsArray addObject:cha.UUID.UUIDString];
        }
        if (mCharacteristicsArray.count > 0) {
            [mArray addObject:@{@"serviceUUID": info.serviceUUID.UUIDString,
                                @"characteristics": mCharacteristicsArray}];
        }
    }
    
    return [mArray copy];
}

// 插入 peripheral 数据 (_retrievedPeripherals，只负责保存 CBPeripheral)
-(void)insertPeripheral:(CBPeripheral *)peripheral {
    if(peripheral && ![_retrievedPeripherals containsObject:peripheral]) {
        [_retrievedPeripherals addObject:peripheral];
    }
}

#pragma mark - utils
#pragma mark 获取当前屏幕显示的 viewController
- (UIViewController *)getCurrentVC
{
    // 定义一个变量存放当前屏幕显示的viewcontroller
    UIViewController *result = nil;
    
    // 得到当前应用程序的主要窗口
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    
    // windowLevel是在 Z轴 方向上的窗口位置，默认值为UIWindowLevelNormal
    if (window.windowLevel != UIWindowLevelNormal)
    {
        // 获取应用程序所有的窗口
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows)
        {
            // 找到程序的默认窗口（正在显示的窗口）
            if (tmpWin.windowLevel == UIWindowLevelNormal)
            {
                // 将关键窗口赋值为默认窗口
                window = tmpWin;
                break;
            }
        }
    }
    
    // 获取窗口的当前显示视图
    UIView *frontView = [[window subviews] objectAtIndex:0];
    
    // 获取视图的下一个响应者，UIView视图调用这个方法的返回值为UIViewController或它的父视图
    id nextResponder = [frontView nextResponder];
    
    // 判断显示视图的下一个响应者是否为一个UIViewController的类对象
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
        result = nextResponder;
    } else {
        result = window.rootViewController;
    }
    return result;
}

- (void)openSettingsURL {
    [self openURLWithString:UIApplicationOpenSettingsURLString];
}

- (void)openURLWithString:(NSString *)str {
    // iOS 10 跳转系统设置 http://www.cnblogs.com/lurenq/p/6189580.html
    // 关于iOS 10，跳转系统设置问题 https://segmentfault.com/q/1010000006978402
    // iOS10跳转系统设置的正确姿势 http://www.jianshu.com/p/bb3f42fdbc31
    // iOS10之后openURL:方法过期之后的替代方法及使用 http://www.cnblogs.com/Jusive/p/6089661.html
    // iOS10适配：被弃用的openURL http://www.cocoachina.com/ios/20161024/17824.html?utm_source=tuicool&utm_medium=referral
    
    NSURL * url = [NSURL URLWithString:str];
    
    if(![[UIApplication sharedApplication] canOpenURL:url]) {
        url = [NSURL URLWithString:[str stringByReplacingOccurrencesOfString:@"App-P" withString:@"p"]];
    }
    
    if (SYSTEM_VERSION_LESS_THAN(@"10")) {
        if([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        } else {
            // 不能打开
        }
    } else {
        [[UIApplication sharedApplication] openURL:url options:@{UIApplicationOpenURLOptionUniversalLinksOnly: @NO, UIApplicationOpenURLOptionsSourceApplicationKey : @YES} completionHandler:^(BOOL success) {
            if (!success) {
                // 不能打开
            }
        }];
    }
}

// 开启扫描超时定时器
- (void)startScanTimerWithTimeout:(NSTimeInterval)seconds {
    //
    [self invalidateScanTimer];
    if (seconds > 0) { // <= 0 将一直扫描
        _scanTimer = [self timerRepeatintWithTimeInterval:seconds block:^{
            //停止扫描
            [_bluetoothManager.baby cancelScan];
            [self invalidateScanTimer];
        }];
    }
}

// 关闭扫描超时定时器
- (void)invalidateScanTimer {
    if (_scanTimer) {
        dispatch_source_cancel(_scanTimer);
        _scanTimer = nil;
    }
}

- (dispatch_source_t)timerRepeatintWithTimeInterval:(NSTimeInterval)seconds block:(dispatch_block_t)block {
    
    NSParameterAssert(seconds);
    NSParameterAssert(block);
    
    // 1.创建一个定时器
    // 获取一个全局并发队列
    //dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_queue_t queue = dispatch_get_main_queue();
    // 第四个参数:传递一个队列,该队列对应了将来的回调方法在哪个线程中执行
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    // 2.指定定时器开始的时间和间隔的时间, 以及精准度
    // 间隔时间
    uint64_t interval = (uint64_t)(seconds * NSEC_PER_SEC);
    // 开始时间
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, interval); // 这里开始时间为从现在起一个间隔时间后开始
    
    // 设置定时器
    /*
     第1个参数: 需要给哪个定时器设置
     第2个参数: 定时器开始的时间/DISPATCH_TIME_NOW立即执行
     第3个参数: 定时器开始之后的间隔时间
     第4个参数: 定时器间隔执行的精准度, 传入0代表最精准(尽量的让定时器精准), 传入一个大于0的值, 代表多少秒的范围是可以接受的
     第四个参数存在的意义: 主要是为了提高程序的性能
     注意点: Dispatch的定时器接收的时间是纳秒
     */
    dispatch_source_set_timer(timer, startTime, interval, 0 * NSEC_PER_SEC);
    
    // 3.指定定时器的回调方法
    /*
     第1个参数: 需要给哪个定时器设置
     第2个参数: 需要回调的block
     */
    /*
    dispatch_source_set_event_handler(timer, ^{
        NSLog(@"++++++++++++++ %@", [NSThread currentThread]);
    });
    */
    dispatch_source_set_event_handler(timer, block);
    
    // 4.开启定时器
    dispatch_resume(timer);
    
    return timer;
}

@end
