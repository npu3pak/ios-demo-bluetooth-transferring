//
// Created by Евгений Сафронов on 28.08.14.
// Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "BluetoothPeripheral.h"
#import "Log.h"
#import "Constants.h"
#import "Settings.h"


@implementation BluetoothPeripheral {
    CBPeripheralManager *_peripheralManager;
}

- (id)init {
    self = [super init];
    if (self) {
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
    }

    return self;
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    switch (peripheral.state) {
        case CBPeripheralManagerStateUnknown:
            [Log error:@"PeripheralManager: Не удалось определить статус Bluetooth"];
            break;
        case CBPeripheralManagerStateResetting:
            [Log error:@"PeripheralManager: Связь с сервисом Bluetooth была потеряна"];
            break;
        case CBPeripheralManagerStateUnsupported:
            [Log error:@"PeripheralManager: Нужная версия Bluetooth не поддерживается"];
            break;
        case CBPeripheralManagerStateUnauthorized:
            [Log error:@"PeripheralManager: Приложению было отказано в доступе к Bluetooth"];
            break;
        case CBPeripheralManagerStatePoweredOff:
            [Log error:@"PeripheralManager: Bluetooth выключен"];
            break;
        case CBPeripheralManagerStatePoweredOn:
            [Log success:@"PeripheralManager: Bluetooth включен и готов к использованию"];
            break;
    }
}

- (void)setUp {
    [Log message:@"Загрузка данных и инициализация характеристик сервиса"];
    NSData *messageData = [[Settings testMessage] dataUsingEncoding:NSUTF8StringEncoding];
    CBMutableCharacteristic *messageCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:kAppCharacteristicMessage]
                                                                                        properties:CBCharacteristicPropertyRead
                                                                                             value:messageData
                                                                                       permissions:CBAttributePermissionsReadable];

    NSData *imageData = UIImageJPEGRepresentation([Settings testImage], 1.0);
    CBMutableCharacteristic *imageCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:kAppCharacteristicImage]
                                                                                      properties:CBCharacteristicPropertyRead
                                                                                           value:imageData
                                                                                     permissions:CBAttributePermissionsReadable];
    [Log message:@"Инициализация сервиса"];
    CBMutableService *_peripheralService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:kAppServiceUUID] primary:YES];
    _peripheralService.characteristics = @[messageCharacteristic, imageCharacteristic];

    [Log message:@"Регистрация сервиса"];
    [_peripheralManager addService:_peripheralService];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    if (error)
        [Log error:[NSString stringWithFormat:@"Не удалось зарегистрировать сервис: %@", error.localizedDescription]];
    else {
        [Log message:@"Предоставление общего доступа к сервису"];
        [_peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey : @[service.UUID]}];
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    if (error)
        [Log error:[NSString stringWithFormat:@"Не удалось предоставить общий доступ к сервису: %@", error.localizedDescription]];
    else {
        [Log success:@"К сервису предоставлен общий доступ. Можно подключаться"];
    }
}

- (void)shutDown {
    [_peripheralManager stopAdvertising];
}


@end