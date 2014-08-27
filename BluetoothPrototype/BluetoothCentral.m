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
            [Log error:@"Не удалось определить статус Bluetooth"];
            break;
        case CBCentralManagerStateResetting:
            [Log error:@"Связь с сервисом Bluetooth была потеряна"];
            break;
        case CBCentralManagerStateUnsupported:
            [Log error:@"Нужная версия Bluetooth не поддерживается"];
            break;
        case CBCentralManagerStateUnauthorized:
            [Log error:@"Приложению было отказано в доступе к Bluetooth"];
            break;
        case CBCentralManagerStatePoweredOff:
            [Log error:@"Bluetooth выключен"];
            break;
        case CBCentralManagerStatePoweredOn:
            [Log success:@"Bluetooth включен и готов к использованию"];
            break;
    }
}

#pragma mark Сканирование

- (void)startScanForDevices {
    if (_centralManager.state != CBCentralManagerStatePoweredOn) {
        [Log error:@"Bluetooth недоступен. Поиск устройств отменен"];
        return;
    }
    [Log message:@"Начинается сканирование устройств"];
    [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kAppServiceUUID]] options:nil];
}

- (void)stopScanForDevices {
    [_centralManager stopScan];
    [Log message:@"Сканирование устройств прекращено"];
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    [Log success:[NSString stringWithFormat:@"Найдено устройство %@", peripheral.name]];
    [Log message:[NSString stringWithFormat:@"Начинается подключение к устройству %@", peripheral.name]];
    [_centralManager connectPeripheral:peripheral options:nil]; //Таймаута нет! Будет долбиться до победного. Нужно отменять запросы явно
}

#pragma mark Подключение

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [Log success:[NSString stringWithFormat:@"Подключение к устройству %@ установлено", peripheral.name]];
    peripheral.delegate = self;
    [Log message:@"Подключение к сервису устройства"];
    [peripheral discoverServices:@[[CBUUID UUIDWithString:kAppServiceUUID]]];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [Log error:[NSString stringWithFormat:@"Не удалось подключиться к устройству %@", peripheral.name]];
}

#pragma mark Обмен данными

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        [Log error:[NSString stringWithFormat:@"Ошибка подключения к сервису: %@", error.localizedDescription]];
    }
    else {
        [Log success:@"Сервис подключен. Получаем информацию о характеристиках сервиса"];
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kAppCharacteristicMessage], [CBUUID UUIDWithString:kAppCharacteristicImage]]
                                 forService:peripheral.services[0]];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        [Log error:[NSString stringWithFormat:@"Ошибка получение характеристик: %@", error.localizedDescription]];
    }
    else {
        [Log success:@"Характеристики получены"];
        for (CBCharacteristic *characteristic in service.characteristics) {
            [Log message:[NSString stringWithFormat:@"Получаем значение характеристики %@", characteristic.UUID.UUIDString]];
            [peripheral readValueForCharacteristic:characteristic];
        }

    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSData *data = characteristic.value;
    [Log success:[NSString stringWithFormat:@"Получено значение характеристики %@. Размер %d кб", characteristic.UUID.UUIDString, (int) (data.length / 1024)]];
}


@end