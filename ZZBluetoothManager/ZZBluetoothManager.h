//
//  ZZBluetoothManager.h
//  ZZBluetoothManagerDemo
//
//  Created by LarryZhang on 2021/12/29.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@class ZZPeripheral;

@protocol ZZBluetoothManagerDelegate <NSObject>

@optional

- (void)managerDidUpdateState:(CBManagerState)state;

- (void)managerScanState:(BOOL)scanning;

- (void)managerDidDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;

- (void)managerDidDiscoverMorePeripheral:(NSDictionary<NSUUID *, ZZPeripheral *> *)allPeripheral;

- (void)managerDidConnectPeripheral:(CBPeripheral *)peripheral;

- (void)managerDidFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;

- (void)managerDidDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;

- (void)peripheralDidDiscoverServices:(NSArray<CBService *> *)services;

- (void)peripheralDidDiscoverCharacteristicsForService:(NSArray<CBCharacteristic *> *)characteristics;

- (void)peripheralDidUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic;

- (void)peripheralDidUpdateValueForCharacteristic:(CBCharacteristic *)characteristic;

@end



@interface ZZBluetoothManager : NSObject

@property(nonatomic, assign, readonly, getter=isScanning) BOOL scanning;

@property(nonatomic, assign, readonly) CBManagerState state;

@property (nonatomic, weak) id<ZZBluetoothManagerDelegate> delegate;

+ (instancetype)sharedManager;

@end



@interface ZZBluetoothManager (scan)

- (void)scanWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs;

- (void)stopScan;

- (NSDictionary<NSUUID *, ZZPeripheral *> *)allDidScanPeripheral;

@end


@interface ZZBluetoothManager (connect)

- (void)connectPeripheral:(ZZPeripheral *)peripheral;

- (void)disconnectPeripheral;

- (void)discoverServices:(nullable NSArray<CBUUID *> *)serviceUUIDs;

- (void)discoverCharacteristics:(nullable NSArray<CBUUID *> *)characteristicUUIDs forService:(CBService *)service;

- (void)writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type;

- (void)setNotifyValue:(BOOL)enabled forCharacteristic:(CBCharacteristic *)characteristic;

@end




@interface ZZPeripheral : NSObject

@property(nonatomic, strong) CBPeripheral *peripheral;

@property(nonatomic, strong) NSDictionary *advertisementData;

@property(nonatomic, strong) NSNumber *RSSI;

@property(nonatomic, assign) NSTimeInterval timestamp;

@end

NS_ASSUME_NONNULL_END
