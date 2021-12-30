//
//  ZZBluetoothManager.m
//  ZZBluetoothManagerDemo
//
//  Created by LarryZhang on 2021/12/29.
//

#import "ZZBluetoothManager.h"

@interface ZZBluetoothManager () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property(nonatomic, strong) CBCentralManager *centralManager;

@property(nonatomic, strong) NSMutableDictionary<NSUUID *, ZZPeripheral *> *allPeripherals;


@property(nonatomic, strong) ZZPeripheral *curPeripheral;

@property(nonatomic, strong) NSArray<CBService *> *services;

@property(nonatomic, strong) NSMutableDictionary<NSString *, NSArray<CBCharacteristic *> *> *allCharacteristics;

@end

@implementation ZZBluetoothManager

+ (instancetype)sharedManager {
    static ZZBluetoothManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        if (_centralManager == nil) {
            _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        }
    }
    return self;
}

#pragma mark ----scan

- (void)scanWithServices:(NSArray<CBUUID *> *)serviceUUIDs {
    _allPeripherals = [NSMutableDictionary dictionary];
    if (self.centralManager.state == CBManagerStatePoweredOn) {
        _scanning = YES;
        if ([self.delegate respondsToSelector:@selector(managerScanState:)]) {
            [self.delegate managerScanState:_scanning];
        }
        [self.centralManager scanForPeripheralsWithServices:serviceUUIDs options:nil];
    }
}

- (void)stopScan {
    [self.centralManager stopScan];
    _scanning = NO;
    if ([self.delegate respondsToSelector:@selector(managerScanState:)]) {
        [self.delegate managerScanState:_scanning];
    }
}

- (NSDictionary<NSUUID *,ZZPeripheral *> *)allDidScanPeripheral {
    return [_allPeripherals copy];
}

#pragma mark ----connect

-(void)connectPeripheral:(ZZPeripheral *)peripheral {
    _curPeripheral = nil;
    _services = nil;
    _allCharacteristics = [NSMutableDictionary dictionary];
    if (peripheral) {
        _curPeripheral = peripheral;
        [self.centralManager connectPeripheral:_curPeripheral.peripheral options:nil];
    }
}

-(void)disconnectPeripheral {
    if (self.curPeripheral && self.curPeripheral.peripheral) {
        [self.centralManager cancelPeripheralConnection:self.curPeripheral.peripheral];
    }
}

- (void)discoverServices:(nullable NSArray<CBUUID *> *)serviceUUIDs {
    if (_curPeripheral.peripheral) {
        [_curPeripheral.peripheral discoverServices:serviceUUIDs];
        _curPeripheral.peripheral.delegate = self;
    }
}

- (void)discoverCharacteristics:(nullable NSArray<CBUUID *> *)characteristicUUIDs forService:(CBService *)service {
    if (_curPeripheral.peripheral) {
        [_curPeripheral.peripheral discoverCharacteristics:characteristicUUIDs forService:service];
    }
}

- (void)writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type {
    if (_curPeripheral.peripheral) {
        [_curPeripheral.peripheral writeValue:data forCharacteristic:characteristic type:type];
    }
}

- (void)setNotifyValue:(BOOL)enabled forCharacteristic:(CBCharacteristic *)characteristic {
    if (_curPeripheral.peripheral) {
        [_curPeripheral.peripheral setNotifyValue:enabled forCharacteristic:characteristic];
    }
}

#pragma mark ----CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    _state = central.state;
    if ([self.delegate respondsToSelector:@selector(managerDidUpdateState:)]) {
        [self.delegate managerDidUpdateState:_state];
    } else {
        NSLog(@"%s state:%@", __func__, @(_state));
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {
    if ([self.delegate respondsToSelector:@selector(managerDidDiscoverPeripheral:advertisementData:RSSI:)]) {
        [self.delegate managerDidDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
    } else {
        NSLog(@"peripheral:%@ %@ %@", peripheral.identifier, peripheral.name, @(peripheral.state));
    }
    
    ZZPeripheral *per = [_allPeripherals objectForKey:peripheral.identifier];
    if (per != nil) {
        per.peripheral = peripheral;
        per.advertisementData = advertisementData;
        per.RSSI = RSSI;
        per.timestamp = [NSDate date].timeIntervalSince1970;
    } else {
        per = [ZZPeripheral new];
        per.peripheral = peripheral;
        per.advertisementData = advertisementData;
        per.RSSI = RSSI;
        per.timestamp = [NSDate date].timeIntervalSince1970;
        [_allPeripherals setObject:per forKey:peripheral.identifier];
        
        if ([self.delegate respondsToSelector:@selector(managerDidDiscoverMorePeripheral:)]) {
            [self.delegate managerDidDiscoverMorePeripheral:[_allPeripherals copy]];
        } else {
            NSLog(@"%s _allPeripherals.count:%@", __func__, @(_allPeripherals.count));
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    if ([self.delegate respondsToSelector:@selector(managerDidConnectPeripheral:)]) {
        [self.delegate managerDidConnectPeripheral:peripheral];
    } else {
        NSLog(@"didConnectPeripheral:%@", peripheral.description);
    }
    
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(managerDidFailToConnectPeripheral:error:)]) {
        [self.delegate managerDidFailToConnectPeripheral:peripheral error:error];
    } else {
        NSLog(@"didFailToConnectPeripheral:%@ error:%@", peripheral.description, error);
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(managerDidDisconnectPeripheral:error:)]) {
        [self.delegate managerDidDisconnectPeripheral:peripheral error:error];
    } else {
        NSLog(@"didDisconnectPeripheral:%@ error:%@", peripheral.description, error);
    }
}

#pragma mark ----CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    _services = peripheral.services;
    if ([self.delegate respondsToSelector:@selector(peripheralDidDiscoverServices:)]) {
        [self.delegate peripheralDidDiscoverServices:peripheral.services];
    } else {
        NSLog(@"didDiscoverServices:%@", peripheral.description);
        NSLog(@"peripheral.services:%@", peripheral.services);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(nonnull CBService *)service error:(nullable NSError *)error {
//    _allCharacteristics[service.UUID.UUIDString] = service.characteristics;
    [_allCharacteristics setObject:service.characteristics forKey:service.UUID.UUIDString];
    
    if ([self.delegate respondsToSelector:@selector(peripheralDidDiscoverCharacteristicsForService:)]) {
        [self.delegate peripheralDidDiscoverCharacteristicsForService:service.characteristics];
    } else {
        NSLog(@"didDiscoverCharacteristicsForService:%@", service.description);
        NSLog(@"service.characteristics:%@", service.characteristics);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(peripheralDidUpdateNotificationStateForCharacteristic:)]) {
        [self.delegate peripheralDidUpdateNotificationStateForCharacteristic:characteristic];
    } else {
        NSLog(@"didUpdateNotificationStateForCharacteristic:%@", characteristic.description);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(peripheralDidUpdateValueForCharacteristic:)]) {
        [self.delegate peripheralDidUpdateValueForCharacteristic:characteristic];
    } else {
        NSLog(@"didUpdateValueForCharacteristic:%@", characteristic.description);
    }
}


@end



@implementation ZZPeripheral

@end
