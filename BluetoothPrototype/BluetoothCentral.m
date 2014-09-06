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
    NSNumber *_imageDataSize;

    NSString *_message;
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
    if (_centralManager.state != CBCentralManagerStatePoweredOn) {
        [Log error:@"Bluetooth недоступен. Поиск устройств отменен"];
        return;
    }
    [_centralManager stopScan];
    [self cleanup];
    [Log message:@"Начинается сканирование устройств"];
    [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kAppServiceUUID]] options:nil];
}

- (void)stopScanForDevices {
    if (_centralManager.state != CBCentralManagerStatePoweredOn) {
        [Log error:@"Bluetooth недоступен. Нечего отменять"];
        return;
    }
    [_centralManager stopScan];
    [self cleanup];
    [Log message:@"Получение даных отменено"];
}

- (void)cleanup {
    _imageDataSize = nil;
    _imageData = [NSMutableData new];
    _message = nil;
    // See if we are subscribed to a characteristic on the peripheral
    if (_currentPeripheral.services != nil) {
        for (CBService *service in _currentPeripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if (characteristic.isNotifying) {
                        [_currentPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                        return;
                    }
                }
            }
        }
    }

    if (_currentPeripheral)
        [_centralManager cancelPeripheralConnection:_currentPeripheral];
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    [_centralManager stopScan];
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
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kAppCharacteristicImage], [CBUUID UUIDWithString:kAppCharacteristicMessage]]
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
            if ([characteristic.UUID.UUIDString isEqualToString:kAppCharacteristicImage])
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            else if ([characteristic.UUID.UUIDString isEqualToString:kAppCharacteristicMessage]) {
                [peripheral readValueForCharacteristic:characteristic];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        [self cleanup];
        [Log error:[NSString stringWithFormat:@"Ошибка %@", error.localizedDescription]];
        return;
    }
    if ([characteristic.UUID.UUIDString isEqualToString:kAppCharacteristicImage]) {
        [self imageCharacteristicUpdated:characteristic];
    }
    if ([characteristic.UUID.UUIDString isEqualToString:kAppCharacteristicMessage]) {
        [self messageCharacteristicUpdated:characteristic];
    }
}

- (void)imageCharacteristicUpdated:(CBCharacteristic *)characteristic {
    if (!_imageDataSize) {
        NSString *size = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        [Log message:[NSString stringWithFormat:@"Начинается передача картинки размером %@ байт", size]];
        _imageDataSize = @(size.intValue);
    } else {
        [_imageData appendData:characteristic.value];
        [self.delegate updateLoadingStatus:_imageData.length maxValue:_imageDataSize.intValue];
        if (_imageData.length >= _imageDataSize.intValue) {
            [Log success:[NSString stringWithFormat:@"Получена картинка %@. Размер %d байт", characteristic.UUID.UUIDString, _imageData.length]];
            UIImage *image = [[UIImage alloc] initWithData:_imageData];
            [self.delegate showImage:image message:_message.copy];
            [self cleanup];
        }
    }
}

- (void)messageCharacteristicUpdated:(CBCharacteristic *)characteristic {
    _message = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    [Log success:[NSString stringWithFormat:@"Получен текст: %@", _message]];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:kAppCharacteristicImage]]) {
        [Log error:[NSString stringWithFormat:@"Ошибка %@", error.localizedDescription]];
        [self cleanup];
        return;
    }
    if (characteristic.isNotifying) {
        [Log message:[NSString stringWithFormat:@"Подписываемся на %@", characteristic.UUID.UUIDString]];
    } else {
        [Log message:[NSString stringWithFormat:@"Отменяем подписку на %@", characteristic.UUID.UUIDString]];
        [_centralManager cancelPeripheralConnection:peripheral];
    }
}

@end