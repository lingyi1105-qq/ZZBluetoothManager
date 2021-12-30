//
//  ViewController.m
//  ZZBluetoothManagerDemo
//
//  Created by LarryZhang on 2021/12/29.
//

#import "ViewController.h"
#import "ZZBluetoothManager.h"

@interface ViewController () <ZZBluetoothManagerDelegate>

@property (nonatomic, strong) ZZBluetoothManager *manager;

@property(nonatomic, strong) CBCharacteristic *notifyCharacteristic;
@property(nonatomic, strong) CBCharacteristic *writeCharacteristic;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    self.manager = [ZZBluetoothManager sharedManager];
    self.manager = [ZZBluetoothManager new];
    self.manager.delegate = self;
}


#pragma mark ----ZZBluetoothManagerDelegate

- (void)managerDidUpdateState:(CBManagerState)state {
    NSLog(@"%s state:%@", __func__, @(state));
    if (state == CBManagerStatePoweredOn) {
        CBUUID *uuid = [CBUUID UUIDWithString:@"FFE0"];
        [self.manager scanWithServices:@[uuid]];
//        [self.manager scanWithServices:nil];
    }
    
//    CBManagerStateUnknown = 0,
//    CBManagerStateResetting,
//    CBManagerStateUnsupported,
//    CBManagerStateUnauthorized,
//    CBManagerStatePoweredOff,
//    CBManagerStatePoweredOn,
}

- (void)managerScanState:(BOOL)scanning {
    NSLog(@"%s scanning:%@", __func__, @(scanning));
}

- (void)managerDidDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"peripheral:%@ %@ %@", peripheral.identifier, peripheral.name, @(peripheral.state));

    NSString *localName = [advertisementData valueForKey:CBAdvertisementDataLocalNameKey];
    NSString *txPowerLevel = [advertisementData valueForKey:CBAdvertisementDataTxPowerLevelKey];
    NSArray *serviceUUIDs = [advertisementData valueForKey:CBAdvertisementDataServiceUUIDsKey];
    NSData *manufactureData = [advertisementData valueForKey:CBAdvertisementDataManufacturerDataKey];
    NSArray *overflowServiceUUIDs = [advertisementData valueForKey:CBAdvertisementDataOverflowServiceUUIDsKey];
    NSString *isConnectable = [advertisementData valueForKey:CBAdvertisementDataIsConnectable];
    NSArray *solicitedServiceUUIDs = [advertisementData valueForKey:CBAdvertisementDataSolicitedServiceUUIDsKey];
    NSLog(@"localName:%@ serviceUUIDs:%@ RSSI:%@ isConnectable:%@ manufactureData:%@", localName, serviceUUIDs.description, RSSI, isConnectable, manufactureData);
    NSLog(@"txPowerLevel:%@ overflowServiceUUIDs:%@ solicitedServiceUUIDs:%@", txPowerLevel, overflowServiceUUIDs, solicitedServiceUUIDs);
    
    
    if (peripheral.services) {
        NSLog(@"peripheral:%@", peripheral);
    }
    
    if ((peripheral.name && [peripheral.name.lowercaseString containsString:@"ailink"])
        || (localName && [localName.lowercaseString containsString:@"ailink"])) {
        [self.manager stopScan];
        
        ZZPeripheral *per = [ZZPeripheral new];
        per.peripheral = peripheral;
        per.advertisementData = advertisementData;
        per.RSSI = RSSI;
        per.timestamp = [NSDate date].timeIntervalSince1970;
        [self.manager connectPeripheral:per];
    }
    
}

- (void)managerDidDiscoverMorePeripheral:(NSDictionary<NSUUID *,ZZPeripheral *> *)allPeripheral {
    NSLog(@"%s allPeripheral.count:%@", __func__, @(allPeripheral.count));
    NSLog(@"");
}

- (void)managerDidConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"%s :%@", __func__, peripheral.description);
    CBUUID *uuid = [CBUUID UUIDWithString:@"FFE0"];
    [self.manager discoverServices:@[uuid]];
//    [self.manager discoverServices:nil];
}

- (void)managerDidFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"%s :%@ error:%@", __func__, peripheral.description, error);
}

- (void)managerDidDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"%s :%@ error:%@", __func__, peripheral.description, error);
}

- (void)peripheralDidDiscoverServices:(NSArray<CBService *> *)services {
    NSLog(@"%s services:%@", __func__, services);
    if (services != nil) {
        for (CBService *service in services) {
            [self.manager discoverCharacteristics:nil forService:service];
        }
    }
}

- (void)peripheralDidDiscoverCharacteristicsForService:(NSArray<CBCharacteristic *> *)characteristics {
    NSLog(@"%s characteristics:%@", __func__, characteristics);
    
    for (CBCharacteristic *characteristic in characteristics) {
        
        if (characteristic.properties & CBCharacteristicPropertyNotify) {
            self.notifyCharacteristic = characteristic;
            [self.manager setNotifyValue:YES forCharacteristic:self.notifyCharacteristic];
        }
        if (characteristic.properties & CBCharacteristicPropertyWrite) {
            self.writeCharacteristic = characteristic;
        }
        
    }
}

- (void)peripheralDidUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"%s characteristic:%@", __func__, characteristic);
    
}

- (void)peripheralDidUpdateValueForCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"%s characteristic:%@", __func__, characteristic);
    
}


@end
