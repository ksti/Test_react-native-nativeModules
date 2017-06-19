//
//  BluetoothManager.m
//  YuanXinBluetooth
//
//  Created by forp on 2017/5/25.
//  Copyright © 2017年 GJS. All rights reserved.
//

#import "BluetoothManager.h"

#define kChannelOnPeripheral @"ChannelOnPeripheral"

@interface BluetoothManager() {
    NSMutableArray *peripheralDataArray;
    BabyBluetooth *baby;
    BluetoothPeripheralObject *peripheralObject;
    BluetoothCharacteristicObject *characteristicObject;
    MMReceiptManager *receiptManager;
}

@end

@implementation BluetoothManager

@synthesize baby;

//单例模式
+ (instancetype)shareInstance {
    static BluetoothManager *share = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        share = [[BluetoothManager alloc] init];
    });
    return share;
}

- (BabyBluetooth *)baby {
    if (!baby) {
        //初始化BabyBluetooth 蓝牙库
        baby = [BabyBluetooth shareBabyBluetooth]; // 在初始化[[CBCentralManager alloc]initWithDelegate:self queue:nil] 时就会触发蓝牙状态的更新，所以放到之后初始化
        //设置蓝牙委托
        [self babyDelegate];
        //设置委托后直接可以使用，无需等待CBCentralManagerStatePoweredOn状态
        //baby.scanForPeripherals().begin();
    }
    return baby;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        //
        peripheralDataArray = [[NSMutableArray alloc] init];
        receiptManager = [[MMReceiptManager alloc] init];
    }
    return self;
}

- (void)dealloc {
    // 2s后，停止扫描，断开连接
    baby.stop(2);
}

#pragma mark -蓝牙配置和操作
// 同一个 baby 可以设置所有委托，然我这里又把它们分开。。
// 蓝牙网关初始化和委托方法设置
- (void)babyDelegate {
    
    __weak typeof(self) weakSelf = self;
    [baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        _bluetoothState = central.state;
        if (central.state == CBCentralManagerStatePoweredOn) {
            NSLog(@"设备打开成功");
        }
        // 回调
        if (weakSelf.onCentralManagerDidUpdateState) {
            weakSelf.onCentralManagerDidUpdateState(central);
        }
    }];
    
    //设置扫描到设备的委托
    [baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        NSLog(@"搜索到了设备:%@",peripheral.name);
        NSLog(@"%@ 广播包 advertisementData:%@", peripheral.name, advertisementData);
        NSLog(@"%@ 信号强度 RSSI:%@", peripheral.name, RSSI);
        [weakSelf insertPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
        // 回调
        if (weakSelf.onDiscoverToPeripherals) {
            weakSelf.onDiscoverToPeripherals(central, peripheral, advertisementData, RSSI);
        }
    }];
    
    //设置查找设备的过滤器
    [baby setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        
        //最常用的场景是查找某一个前缀开头的设备
        //        if ([peripheralName hasPrefix:@"Pxxxx"] ) {
        //            return YES;
        //        }
        //        return NO;
        
        //设置查找规则是名称大于0 ， the search rule is peripheral.name length > 0
        if (peripheralName.length >0) {
            return YES;
        }
        return NO;
    }];
    
    
    [baby setBlockOnCancelAllPeripheralsConnectionBlock:^(CBCentralManager *centralManager) {
        NSLog(@"setBlockOnCancelAllPeripheralsConnectionBlock");
    }];
    
    [baby setBlockOnCancelScanBlock:^(CBCentralManager *centralManager) {
        NSLog(@"setBlockOnCancelScanBlock");
    }];
    
    
    /*设置babyOptions
     
     参数分别使用在下面这几个地方，若不使用参数则传nil
     - [centralManager scanForPeripheralsWithServices:scanForPeripheralsWithServices options:scanForPeripheralsWithOptions];
     - [centralManager connectPeripheral:peripheral options:connectPeripheralWithOptions];
     - [peripheral discoverServices:discoverWithServices];
     - [peripheral discoverCharacteristics:discoverWithCharacteristics forService:service];
     
     该方法支持channel版本:
     [baby setBabyOptionsAtChannel:<#(NSString *)#> scanForPeripheralsWithOptions:<#(NSDictionary *)#> connectPeripheralWithOptions:<#(NSDictionary *)#> scanForPeripheralsWithServices:<#(NSArray *)#> discoverWithServices:<#(NSArray *)#> discoverWithCharacteristics:<#(NSArray *)#>]
     */
    
    //示例:
    //扫描选项->CBCentralManagerScanOptionAllowDuplicatesKey:忽略同一个Peripheral端的多个发现事件被聚合成一个发现事件
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    //连接设备->
    [self setBabyOptionsWithScanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:nil scanForPeripheralsWithServices:nil discoverWithServices:nil discoverWithCharacteristics:nil];
}

//设置蓝牙使用的参数参数
- (void)setBabyOptionsWithScanForPeripheralsWithOptions:(NSDictionary *) scanForPeripheralsWithOptions
                           connectPeripheralWithOptions:(NSDictionary *) connectPeripheralWithOptions
                         scanForPeripheralsWithServices:(NSArray *)scanForPeripheralsWithServices
                                   discoverWithServices:(NSArray *)discoverWithServices
                            discoverWithCharacteristics:(NSArray *)discoverWithCharacteristics {
    /*设置babyOptions
     
     参数分别使用在下面这几个地方，若不使用参数则传nil
     - [centralManager scanForPeripheralsWithServices:scanForPeripheralsWithServices options:scanForPeripheralsWithOptions];
     - [centralManager connectPeripheral:peripheral options:connectPeripheralWithOptions];
     - [peripheral discoverServices:discoverWithServices];
     - [peripheral discoverCharacteristics:discoverWithCharacteristics forService:service];
     
     该方法支持channel版本:
     [baby setBabyOptionsAtChannel:<#(NSString *)#> scanForPeripheralsWithOptions:<#(NSDictionary *)#> connectPeripheralWithOptions:<#(NSDictionary *)#> scanForPeripheralsWithServices:<#(NSArray *)#> discoverWithServices:<#(NSArray *)#> discoverWithCharacteristics:<#(NSArray *)#>]
     */
    
    //示例:
    //扫描选项->CBCentralManagerScanOptionAllowDuplicatesKey:忽略同一个Peripheral端的多个发现事件被聚合成一个发现事件
    //NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    //连接设备->
    [baby setBabyOptionsWithScanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:connectPeripheralWithOptions scanForPeripheralsWithServices:scanForPeripheralsWithServices discoverWithServices:discoverWithServices discoverWithCharacteristics:discoverWithCharacteristics];
}

#pragma mark - babybluetooth filter委托
//设置查找Peripherals的规则
- (void)setFilterOnDiscoverPeripherals:(BOOL (^)(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI))filter {
    [baby setFilterOnDiscoverPeripherals:filter];
}
//设置连接Peripherals的规则
- (void)setFilterOnConnectToPeripherals:(BOOL (^)(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI))filter {
    [baby setFilterOnConnectToPeripherals:filter];
}
//设置查找Peripherals的规则
- (void)setFilterOnDiscoverPeripheralsAtChannel:(NSString *)channel
                                         filter:(BOOL (^)(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI))filter {
    [baby setFilterOnDiscoverPeripheralsAtChannel:channel filter:filter];
}
//设置连接Peripherals的规则
- (void)setFilterOnConnectToPeripheralsAtChannel:(NSString *)channel
                                          filter:(BOOL (^)(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI))filter {
    [baby setFilterOnConnectToPeripheralsAtChannel:channel filter:filter];
}

#pragma mark -连接外设
/**
 * 开始连接外设
 */
- (void)connectPeripheral:(CBPeripheral *)currPeripheral {
    [self connectPeripheral:currPeripheral withDiscoverSevices:nil];
}
/**
 * 开始连接外设，设置感兴趣的服务
 */
- (void)connectPeripheral:(CBPeripheral *)currPeripheral withDiscoverSevices:(NSArray<CBUUID *> *)servicesToDiscover {
    __weak typeof(self)weakSelf = self;
    if (!peripheralObject) {
        peripheralObject = [[BluetoothPeripheralObject alloc] initWithChannel:KBABY_DETAULT_CHANNEL]; // 默认频道，目前不清楚 BabyBluetooth 这些频道是干嘛使得，如果不在一个频道，蓝牙状态更新也不在一个频道。。比如切换到一个频道时：kChannelOnPeripheral，关闭蓝牙，我上面的蓝牙状态回调不会走了。。所以目前采用同一个频道：默认 KBABY_DETAULT_CHANNEL
    }
    peripheralObject.baby = self.baby; // 使用同一个 BabyBluetooth 对象
    peripheralObject.servicesToDiscover = servicesToDiscover; // 设置感兴趣的服务
    
    // 设置回调
    peripheralObject.onConnectedPeripheral = ^(CBCentralManager *central, CBPeripheral *peripheral) {
        if (weakSelf.onConnectedAtChannel) {
            weakSelf.onConnectedAtChannel(KBABY_DETAULT_CHANNEL, central, peripheral);
        }
    };
    [peripheralObject setOnFailToConnectPeripheral:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        //
        if (weakSelf.onFailToConnectAtChannel) {
            weakSelf.onFailToConnectAtChannel(KBABY_DETAULT_CHANNEL, central, peripheral, error);
        }
    }];
    // 连接外设
    [peripheralObject connectPeripheral:currPeripheral];
}

/**
 * 添加断开自动重连的外设
 */
- (void)AutoReconnect:(CBPeripheral *)peripheral{
    [baby AutoReconnect:peripheral];
}

/**
 * 删除断开自动重连的外设
 */
- (void)AutoReconnectCancel:(CBPeripheral *)peripheral{
    [baby AutoReconnectCancel:peripheral];
}

/**
 * 根据外设UUID对应的string获取已配对的外设
 
 * 通过方法获取外设后可以直接连接外设，跳过扫描过程
 */
- (CBPeripheral *)retrievePeripheralWithUUIDString:(NSString *)UUIDString {
    return [baby retrievePeripheralWithUUIDString:UUIDString];
}

#pragma mark -读取已连接的外设提供的服务、特征
- (NSArray<PeripheralInfo *> *)getPeripheralServices {
    return [peripheralObject.services copy];
}

#pragma mark -订阅指定特征值的变化
/**
 设置characteristic的notify
 */
- (void)notify:(CBPeripheral *)peripheral
characteristic:(CBCharacteristic *)characteristic
         block:(void(^)(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error))block {
    [baby notify:peripheral characteristic:characteristic block:block];
}

/**
 取消characteristic的notify
 */
- (void)cancelNotify:(CBPeripheral *)peripheral
      characteristic:(CBCharacteristic *)characteristic {
    [baby cancelNotify:peripheral characteristic:characteristic];
}

#pragma mark -读取Characteristic的详细信息
// 读取Characteristic的详细信息
- (void)readPeripheral:(CBPeripheral *)peripheral characteristicUUIDString:(NSString *)characteristicUUIDString {
    CBCharacteristic *characteristic = [self findCharacteristicByUUIDString:characteristicUUIDString inDiscoveredServices:[self getPeripheralServices]];
    [self readPeripheral:peripheral characteristicDetails:characteristic];
}
// 读取Characteristic的详细信息
- (void)readPeripheral:(CBPeripheral *)peripheral characteristicDetails:(CBCharacteristic *)characteristic {
    __weak typeof(self)weakSelf = self;
    if (!characteristicObject) {
        characteristicObject = [[BluetoothCharacteristicObject alloc] initWithChannel:KBABY_DETAULT_CHANNEL]; // 默认频道
    }
    characteristicObject.baby = self.baby; // 使用同一个 BabyBluetooth 对象
    
    characteristicObject.currPeripheral = peripheral;
    characteristicObject.characteristic = characteristic;
    
    // 设置回调
    characteristicObject.onReadValueForCharacteristic = ^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        //
        if (weakSelf.onReadValueForCharacteristicAtChannel) {
            weakSelf.onReadValueForCharacteristicAtChannel(KBABY_DETAULT_CHANNEL, peripheral, characteristic, error);
        }
    };
    characteristicObject.onReadValueForDescriptor = ^(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) {
        //
        if (weakSelf.onReadValueForDescriptorAtChannel) {
            weakSelf.onReadValueForDescriptorAtChannel(KBABY_DETAULT_CHANNEL, peripheral, descriptor, error);
        }
    };
    // 读取Characteristic的详细信息
    [characteristicObject readCharacteristicDetails];
}

#pragma mark -向蓝牙发送信息
// 向蓝牙发送信息
- (void)writePeripheral:(CBPeripheral *)peripheral dataWithString:(NSString *)str orInfoData:(NSData *)infoData forCharacteristicUUIDString:(NSString *)characteristicUUIDString {
    CBCharacteristic *characteristic = [self findCharacteristicByUUIDString:characteristicUUIDString inDiscoveredServices:[self getPeripheralServices]];
    [self writePeripheral:peripheral dataWithString:str orInfoData:infoData forCharacteristic:characteristic];
}

// 向蓝牙发送信息
- (void)writePeripheral:(CBPeripheral *)peripheral dataWithString:(NSString *)str orInfoData:(NSData *)infoData forCharacteristic:(CBCharacteristic *)characteristic
{
    __weak typeof(self)weakSelf = self;
    if (!characteristicObject) {
        characteristicObject = [[BluetoothCharacteristicObject alloc] initWithChannel:KBABY_DETAULT_CHANNEL]; // 默认频道
    }
    characteristicObject.baby = self.baby; // 使用同一个 BabyBluetooth 对象
    
    characteristicObject.currPeripheral = peripheral;
    characteristicObject.characteristic = characteristic;
    
    // 设置回调
    characteristicObject.onDidWriteValueForCharacteristic = ^(CBCharacteristic *characteristic, NSError *error) {
        //
        if (weakSelf.onDidWriteValueForCharacteristicAtChannel) {
            weakSelf.onDidWriteValueForCharacteristicAtChannel(KBABY_DETAULT_CHANNEL, characteristic, error);
        }
    };
    // 写一个值
    [characteristicObject writeDataWithString:str orInfoData:infoData];
}

#pragma mark -蓝牙打印
//基础设置
- (void)printerBasicSetting
{
    [receiptManager basicSetting];
}
//清空缓存数据
- (void)printerClearData
{
    [receiptManager clearData];
}

//写入单行文字
- (void)printerWriteData_title:(NSString *)title Scale:(kCharScale)scale Type:(kAlignmentType)type {
    [receiptManager writeData_title:title Scale:scale Type:type];
}
//打印图片
- (void)printerWriteData_image:(UIImage *)image alignment:(kAlignmentType)alignment maxWidth:(CGFloat)maxWidth {
    [receiptManager writeData_image:image alignment:alignment maxWidth:maxWidth];
}
//打印图片
- (void)printerWriteData_qrImageStr:(NSString *)qrImageStr alignment:(kAlignmentType)alignment maxWidth:(CGFloat)maxWidth {
    if (qrImageStr) {
        UIImage *qrImage =[MMQRCode createBarImageWithOrderStr:qrImageStr];
        [self printerWriteData_image:qrImage alignment:alignment maxWidth:maxWidth];
    }
}
//写入多行文字
- (void)printerWriteData_items:(NSArray *)items {
    [receiptManager writeData_items:items];
}
//打印分割线
- (void)printerWriteData_line {
    [receiptManager writeData_line];
}
//条目,菜单,有间隔,如:
//  炸鸡排     2      12.50      25.00
- (void)printerWriteData_content:(NSArray *)items {
    NSMutableArray *mArray = [NSMutableArray arrayWithCapacity:items.count];
    for (ReceiptInfo *receipt in items) {
        NSDictionary *dict = @{@"key01": receipt.key01,
                               @"key02": receipt.key02,
                               @"key03": receipt.key03,
                               @"key04": receipt.key04,
                               };
        [mArray addObject:dict];
    }
    [receiptManager writeData_content:[mArray copy]];
}

// 打印小票
- (void)receiptPrint:(CBPeripheral *)peripheral forCharacteristic:(CBCharacteristic *)characteristic {
    [self bluetoothPrint:peripheral forCharacteristic:characteristic withString:nil orInfoData:[receiptManager.printerManager sendData]];
}

// 测试打印小票
- (void)testBluetoothPrintWith:(NSDictionary *)dictionary andPrintType:(NSInteger)typeNum{
    MMReceiptManager *manager = [[MMReceiptManager alloc] init];
    [manager clearData];
    [manager basicSetting];
    [manager writeData_title:@"肯德基" Scale:scale_2 Type:MiddleAlignment];
    UIImage *qrImage =[MMQRCode createBarImageWithOrderStr:@"RN3456789012"];
    [manager writeData_image:qrImage alignment:MiddleAlignment maxWidth:300];
    [manager writeData_items:@[@"收银员:001", @"交易时间:2016-03-17", @"交易号:201603170001"]];
    [manager writeData_line];
    [manager writeData_content:@[@{@"key01":@"名称", @"key02":@"单价", @"key03":@"数量", @"key04":@"总价"}]];
    [manager writeData_line];
    [manager writeData_content:@[@{@"key01":@"汉堡", @"key02":@"10.00", @"key03":@"2", @"key04":@"20.00"}, @{@"key01":@"炸鸡", @"key02":@"8.00", @"key03":@"1", @"key04":@"8.00"}]];
    [manager writeData_line];
    [manager writeData_items:@[@"支付方式:现金", @"应收:28.00", @"实际:30.00", @"找零:2.00"]];
    [manager writeData_title:@"谢谢惠顾" Scale:scale_1 Type:MiddleAlignment];
    [manager writeData_line];
    
    [self bluetoothPrint:nil forCharacteristic:nil withString:nil orInfoData:[manager.printerManager sendData]];
}

// 打印
-(void)bluetoothPrint:(CBPeripheral *)peripheral forCharacteristic:(CBCharacteristic *)characteristic withString:(NSString *)str orInfoData:(NSData *)infoData
{
    [self notify:peripheral characteristic:characteristic block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        //
    }];
    [self writePeripheral:peripheral dataWithString:str orInfoData:infoData forCharacteristic:characteristic];
}

#pragma mark -utils
#pragma mark -插入 peripheral 数据
// 插入 peripheral 数据
-(void)insertPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    NSArray *peripherals = [peripheralDataArray valueForKey:@"peripheral"];
    if(![peripherals containsObject:peripheral]) {
        NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
        [item setValue:peripheral forKey:@"peripheral"];
        [item setValue:RSSI forKey:@"RSSI"]; // 信号和服务
        [item setValue:advertisementData forKey:@"advertisementData"];
        [peripheralDataArray addObject:item];
        
        // peripheral的显示名称,优先用kCBAdvDataLocalName的定义，若没有再使用peripheral name
        NSString *peripheralName;
        if ([advertisementData objectForKey:@"kCBAdvDataLocalName"]) {
            peripheralName = [NSString stringWithFormat:@"%@",[advertisementData objectForKey:@"kCBAdvDataLocalName"]];
        }else if(!([peripheral.name isEqualToString:@""] || peripheral.name == nil)){
            peripheralName = peripheral.name;
        }else{
            peripheralName = [peripheral.identifier UUIDString];
        }
        NSLog(@"discovered a new peripheral: %@", peripheralName);
        
        [self postNotificationName:Notification_DiscoverNewPeripheral object:peripheralDataArray];
    }
}

// 发送通知
- (void)postNotificationName:(NSString*)name object:(id)object {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter postNotificationName:name object:object];
}

// 清除数据
- (void)clearPeripheralsArray {
    [peripheralDataArray removeAllObjects];
}

// 根据 name 查找外设
- (CBPeripheral *)findPeripheralByName:(NSString *)peripheralName {
    return [self findPeripheralByName:peripheralName inDiscoveredPeripherals:[peripheralDataArray valueForKey:@"peripheral"]];
}

// 根据 name 查找外设
- (CBPeripheral *)findPeripheralByName:(NSString *)peripheralName inDiscoveredPeripherals:(NSArray *)connectedPeripherals {
    for (CBPeripheral *p in connectedPeripherals) {
        if ([p.name isEqualToString:peripheralName]) {
            return p;
        }
    }
    return nil;
}

// 根据 identifier 查找外设
- (CBPeripheral *)findPeripheralByIdentifier:(NSString *)peripheralIdentifier {
    return [self findPeripheralByIdentifier:peripheralIdentifier inDiscoveredPeripherals:[peripheralDataArray valueForKey:@"peripheral"]];
}

// 根据 identifier 查找外设
- (CBPeripheral *)findPeripheralByIdentifier:(NSString *)peripheralIdentifier inDiscoveredPeripherals:(NSArray *)connectedPeripherals {
    for (CBPeripheral *p in connectedPeripherals) {
        if ([p.identifier.UUIDString isEqualToString:peripheralIdentifier]) {
            return p;
        }
    }
    return nil;
}

// 根据 UUIDString 查找 characteristic
- (CBCharacteristic *)findCharacteristicByUUIDString:(NSString *)characteristicUUID {
    return [self findCharacteristicByUUIDString:characteristicUUID inDiscoveredServices:[self getPeripheralServices]];
}

// 根据 UUIDString 查找 characteristic
- (CBCharacteristic *)findCharacteristicByUUIDString:(NSString *)characteristicUUID inDiscoveredServices:(NSArray<PeripheralInfo *> *)discoveredServices {
    for (PeripheralInfo *info in discoveredServices) {
        NSArray *discoveredCharacteristics = info.characteristics;
        for (CBCharacteristic *cha in discoveredCharacteristics) {
            if ([cha.UUID.UUIDString isEqualToString:characteristicUUID]) {
                return cha;
            }
        }
    }
    
    return nil;
}

@end
