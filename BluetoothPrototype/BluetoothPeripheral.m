//
// Created by Евгений Сафронов on 28.08.14.
// Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "BluetoothPeripheral.h"
#import "Log.h"
#import "Constants.h"
#import "Settings.h"

@interface BluetoothPeripheral ()

@property id sender;
@property SEL peripheralStartedCallback;
@property SEL peripheralStoppedCallback;
@property CBPeripheralManager *peripheralManager;

@end

//TODO В настройки
#define MTU 120

@implementation BluetoothPeripheral {
    NSData *_imageData;
    int _sendDataIndex;
    CBMutableCharacteristic *_imageCharacteristic;
}

- (instancetype)initWithSender:(id)sender peripheralStartedCallback:(SEL)peripheralStartedCallback peripheralStoppedCallback:(SEL)peripheralStoppedCallback {
    self = [super init];
    if (self) {
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
        self.sender = sender;
        self.peripheralStartedCallback = peripheralStartedCallback;
        self.peripheralStoppedCallback = peripheralStoppedCallback;
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

    if (peripheral.state == CBPeripheralManagerStatePoweredOn && peripheral.isAdvertising)
        [self notifyPeripheralStart];
    else
        [self notifyPeripheralStop];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (void)notifyPeripheralStart {
    if (self.sender && self.peripheralStartedCallback)
        [self.sender performSelector:self.peripheralStartedCallback];
}

- (void)notifyPeripheralStop {
    if (self.sender && self.peripheralStoppedCallback)
        [self.sender performSelector:self.peripheralStoppedCallback];
}
#pragma clang diagnostic pop

- (void)shutDown {
    if (self.peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        [Log error:@"Bluetooth недоступен. Нечего отменять. Отправка данных и так не выполнялась"];
        return;
    }
    [self.peripheralManager stopAdvertising];
    [Log success:@"Раздача данных отключена. Устройство больше не доступно для обнаружения"];
}

- (void)setUp {
    if (self.peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        [Log error:@"Bluetooth недоступен. Отправка данных отменена"];
        [self notifyPeripheralStop];
        return;
    }
    _imageData = UIImageJPEGRepresentation([Settings testImage], 1.0);
    _imageCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:kAppCharacteristicImage]
                                                              properties:CBCharacteristicPropertyNotify
                                                                   value:nil
                                                             permissions:CBAttributePermissionsReadable];
    CBMutableService *_peripheralService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:kAppServiceUUID] primary:YES];
    _peripheralService.characteristics = @[_imageCharacteristic];
    [self.peripheralManager addService:_peripheralService];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    if (error) {
        [self notifyPeripheralStop];
        [Log error:[NSString stringWithFormat:@"Не удалось зарегистрировать сервис: %@", error.localizedDescription]];
    }
    else {
        [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey : @[service.UUID]}];
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    if (error) {
        [self notifyPeripheralStop];
        [Log error:[NSString stringWithFormat:@"Не удалось предоставить общий доступ к сервису: %@", error.localizedDescription]];
    }
    else {
        [Log success:@"К данным предоставлен общий доступ. Можно подключаться"];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    if ([characteristic.UUID.UUIDString isEqualToString:kAppCharacteristicImage]) {
        _sendDataIndex = 0;
        [self sendData];
    }
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    [self sendData];
}

/*
    Дробление картинки на порции и координирование отправки.
    Взято отсюда: http://stackoverflow.com/questions/18476335/sending-image-file-over-bluetooth-4-0-le
 */

- (void)sendData {
    static BOOL sendingEOM = NO;
    // end of message?
    if (sendingEOM) {
        BOOL didSend = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:_imageCharacteristic onSubscribedCentrals:nil];

        if (didSend) {
            // It did, so mark it as sent
            sendingEOM = NO;
        }
        // didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
        return;
    }

    // We're sending data
    // Is there any left to send?
    if (_sendDataIndex >= _imageData.length) {
        // No data left.  Do nothing
        return;
    }

    // There's data left, so send until the callback fails, or we're done.
    BOOL didSend = YES;

    while (didSend) {
        // Work out how big it should be
        int amountToSend = _imageData.length - _sendDataIndex;

        // Can't be longer than 20 bytes
        if (amountToSend > MTU) amountToSend = MTU;

        // Copy out the data we want
        NSData *chunk = [_imageData subdataWithRange:NSMakeRange((NSUInteger) _sendDataIndex, (NSUInteger) amountToSend)];

        didSend = [self.peripheralManager updateValue:chunk forCharacteristic:_imageCharacteristic onSubscribedCentrals:nil];

        // If it didn't work, drop out and wait for the callback
        if (!didSend) {
            return;
        }

        // It did send, so update our index
        _sendDataIndex += amountToSend;

        // Was it the last one?
        if (_sendDataIndex >= _imageData.length) {

            // Set this so if the send fails, we'll send it next time
            sendingEOM = YES;

            BOOL eomSent = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:_imageCharacteristic onSubscribedCentrals:nil];

            if (eomSent) {
                // It sent, we're all done
                sendingEOM = NO;
                [Log success:[NSString stringWithFormat:@"Передача завершена. Передано %d байт", _imageData.length]];
            }
            return;
        }
    }
}


@end