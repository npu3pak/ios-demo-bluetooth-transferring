//
// Created by Евгений Сафронов on 06.09.14.
// Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import "BluetoothInitiateConnectionCentral.h"
#import "Log.h"
#import "Constants.h"


@implementation BluetoothInitiateConnectionCentral {
    CBCentralManager *_centralManager;
    CBPeripheral *_currentPeripheral;
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
            [Log error:@"CentralManager2: Не удалось определить статус Bluetooth"];
            break;
        case CBCentralManagerStateResetting:
            [Log error:@"CentralManager2: Связь с сервисом Bluetooth была потеряна"];
            break;
        case CBCentralManagerStateUnsupported:
            [Log error:@"CentralManager2: Нужная версия Bluetooth не поддерживается"];
            break;
        case CBCentralManagerStateUnauthorized:
            [Log error:@"CentralManager2: Приложению было отказано в доступе к Bluetooth"];
            break;
        case CBCentralManagerStatePoweredOff:
            [Log error:@"CentralManager2: Bluetooth выключен"];
            break;
        case CBCentralManagerStatePoweredOn:
            [Log success:@"CentralManager2: Bluetooth включен и готов к использованию"];
            break;
    }
}

#pragma mark Сканирование

- (void)initiateConnection {
    if (_centralManager.state != CBCentralManagerStatePoweredOn) {
        [Log error:@"Bluetooth недоступен. Поиск устройств отменен"];
        return;
    }
    [_centralManager stopScan];
    [self cleanup];
    [Log message:@"Начинается сканирование устройств"];
    [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kAppServiceUUID]] options:nil];

}

- (void)cleanup {
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
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kAppCharacteristicInitiateConnection]]
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
            if ([characteristic.UUID.UUIDString isEqualToString:kAppCharacteristicInitiateConnection])
                [peripheral writeValue:NSData.new forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
        }
    }
}

@end