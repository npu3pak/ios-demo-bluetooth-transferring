//
// Created by Евгений Сафронов on 27.08.14.
// Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "BluetoothCentral.h"
#import "Log.h"
#import "Constants.h"


@implementation BluetoothCentral {
    CBCentralManager *_centralManager;
    CBPeripheral *_currentPeripheral;
    NSMutableData *_imageData;
}

- (id)init {
    self = [super init];
    if (self) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    }

    return self;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            [Log error:@"CentralManager: Не удалось определить статус Bluetooth"];
            break;
        case CBCentralManagerStateResetting:
            [Log error:@"CentralManager: Связь с сервисом Bluetooth была потеряна"];
            break;
        case CBCentralManagerStateUnsupported:
            [Log error:@"CentralManager: Нужная версия Bluetooth не поддерживается"];
            break;
        case CBCentralManagerStateUnauthorized:
            [Log error:@"CentralManager: Приложению было отказано в доступе к Bluetooth"];
            break;
        case CBCentralManagerStatePoweredOff:
            [Log error:@"CentralManager: Bluetooth выключен"];
            break;
        case CBCentralManagerStatePoweredOn:
            [Log success:@"CentralManager: Bluetooth включен и готов к использованию"];
            break;
    }
}

#pragma mark Сканирование

- (void)startScanForDevices {
    _imageData = [NSMutableData new];
    if (_centralManager.state != CBCentralManagerStatePoweredOn) {
        [Log error:@"Bluetooth недоступен. Поиск устройств отменен"];
        return;
    }
    [Log message:@"Начинается сканирование устройств"];
    [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kAppServiceUUID]] options:nil];
}

- (void)stopScanForDevices {
    if (_centralManager.state != CBCentralManagerStatePoweredOn) {
        [Log error:@"Bluetooth недоступен. Нечего отменять"];
        return;
    }
    [_centralManager stopScan];
    [Log message:@"Сканирование устройств прекращено"];
}

- (void)cleanup {
    _imageData = [NSMutableData new];
    // See if we are subscribed to a characteristic on the peripheral
    if (_currentPeripheral.services != nil) {
        for (CBService *service in _currentPeripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kAppCharacteristicImage]]) {
                        if (characteristic.isNotifying) {
                            [_currentPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                            return;
                        }
                    }
                }
            }
        }
    }

    [_centralManager cancelPeripheralConnection:_currentPeripheral];
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    [self stopScanForDevices];
    _currentPeripheral = peripheral;
    [_centralManager connectPeripheral:peripheral options:nil]; //Таймаута нет! Будет долбиться до победного. Нужно отменять запросы явно
}

#pragma mark Подключение

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    peripheral.delegate = self;
    [peripheral discoverServices:@[[CBUUID UUIDWithString:kAppServiceUUID]]];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [Log error:[NSString stringWithFormat:@"Не удалось подключиться к устройству %@", peripheral.name]];
}

#pragma mark Обмен данными

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        [self cleanup];
        [Log error:[NSString stringWithFormat:@"Ошибка подключения к сервису: %@", error.localizedDescription]];
    }
    else {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kAppCharacteristicImage]]
                                 forService:peripheral.services[0]];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        [self cleanup];
        [Log error:[NSString stringWithFormat:@"Ошибка получение характеристик: %@", error.localizedDescription]];
    }
    else {
        for (CBCharacteristic *characteristic in service.characteristics) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        [self cleanup];
        [Log error:[NSString stringWithFormat:@"Ошибка %@", error.localizedDescription]];
        return;
    }
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    // Have we got everything we need?
    if ([stringFromData isEqualToString:@"EOM"]) {
        [Log success:[NSString stringWithFormat:@"Получено значение характеристики %@. Размер %d байт", characteristic.UUID.UUIDString, _imageData.length]];
        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
        [_centralManager cancelPeripheralConnection:peripheral];
    }
    NSData *chunk = characteristic.value;
    [_imageData appendData:chunk];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:kAppCharacteristicImage]]) {
        [Log error:[NSString stringWithFormat:@"Ошибка %@", error.localizedDescription]];
        [self cleanup];
        return;
    }
    if (characteristic.isNotifying) {
        [Log message:[NSString stringWithFormat:@"Характеристика %@ доступна", characteristic]];
    } else {
        [Log message:[NSString stringWithFormat:@"Характеристика %@ больше не доступна", characteristic]];
        [_centralManager cancelPeripheralConnection:peripheral];
    }
}

@end