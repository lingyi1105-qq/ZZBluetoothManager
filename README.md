# ZZBluetoothManager

ZZBluetoothManager 简化二次封装了 CoreBluetooth 部分方法，方便理解 CoreBluetooth 部分方法逻辑，和快速实现与 BLE 外设连接通讯。

ZZBluetoothManager 只实现了 iOS 设备作为 central 端功能，不能实现 peripheral 端的功能。

ZZBluetoothManager 提供了 iOS 设备作为 central 扫描、连接 peripheral 的方法，以及 service 和 characteristic 的相关方法。可以发送数据给 peripheral，也可以监听 peripheral 发送的数据，实现双向通讯。



iOS 设备作为 central 与 peripheral 实现通讯，可以分为两大步骤，

1. 扫描 peripheral

   开始扫描设备

   ```objective-c
   - (void)scanWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs;
   ```

   扫描结果有两种代理方法返回

   ```objective-c
   - (void)managerDidDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;
   
   - (void)managerDidDiscoverMorePeripheral:(NSDictionary<NSUUID *, ZZPeripheral *> *)allPeripheral;
   ```

    (由于不同的产品设计，有些 peripheral 不需要连接，只通过扫描就能实现产品功能)

2. 连接 peripheral， 并获取相关 services 和 characteristics

   连接已知外设

   ```objective-c
   - (void)connectPeripheral:(ZZPeripheral *)peripheral;
   ```

   会有代理方法返回

   ```objective-c
   - (void)managerDidConnectPeripheral:(CBPeripheral *)peripheral;
   
   - (void)managerDidFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
   
   - (void)managerDidDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
   ```

   连接成功后可以获取 services

   ```objective-c
   - (void)discoverServices:(nullable NSArray<CBUUID *> *)serviceUUIDs;
   ```

   代理方法返回

   ```objective-c
   - (void)peripheralDidDiscoverServices:(NSArray<CBService *> *)services;
   ```

   获取到 services 后，去获取 characteristics

   ```objective-c
   - (void)discoverCharacteristics:(nullable NSArray<CBUUID *> *)characteristicUUIDs forService:(CBService *)service;
   ```

   代理方法返回

   ```objective-c
   - (void)peripheralDidDiscoverCharacteristicsForService:(NSArray<CBCharacteristic *> *)characteristics;
   ```

   如果获取的 characteristic 有 CBCharacteristicPropertyNotify 属性，可以使用订阅方法，

   ```objective-c
    (void)setNotifyValue:(BOOL)enabled forCharacteristic:(CBCharacteristic *)characteristic;
   ```

   订阅完成和收到数据有代理方法

   ```objective-c
   - (void)peripheralDidUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic;
   
   - (void)peripheralDidUpdateValueForCharacteristic:(CBCharacteristic *)characteristic;
   ```

   具有 CBCharacteristicPropertyWrite 属性的 characteristic，支持写数据方法

   ```objective-c
   - (void)writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type;
   ```

   



