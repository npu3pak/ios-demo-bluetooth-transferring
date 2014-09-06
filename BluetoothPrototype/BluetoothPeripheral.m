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

typedef enum {
    IDLE, SIZE_SENDING, DATA_SENDING
} SendingState;

@implementation BluetoothPeripheral {
    CBMutableCharacteristic *_messageCharacteristic;
    CBMutableCharacteristic *_imageCharacteristic;
    CBMutableCharacteristic *_initiateConnectionCharacteristic;
    NSData *_imageData;
    int _imagePacketPosition;
    SendingState _imageSendingState;
    NSInteger _mtu;
}

- (instancetype)initWithSender:(id)sender peripheralStartedCallback:(SEL)peripheralStartedCallback peripheralStoppedCallback:(SEL)peripheralStoppedCallback {
    self = [super init];
    if (self) {
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
        self.sender = sender;
        self.peripheralStartedCallback = peripheralStartedCallback;
        self.peripheralStoppedCallback = peripheralStoppedCallback;
        _imageSendingState = IDLE;
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
    _imageSendingState = IDLE;
    [self.peripheralManager stopAdvertising];
    [self.peripheralManager removeAllServices];
    [Log message:@"Раздача данных отключена. Устройство больше не доступно для обнаружения"];
}

- (void)setUp {
    if (self.peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        [Log error:@"Bluetooth недоступен. Отправка данных отменена"];
        [self notifyPeripheralStop];
        return;
    }
    _mtu = Settings.mtu;
    _imageSendingState = IDLE;
    _imageData = UIImageJPEGRepresentation([Settings testImage], kImageQuality);
    _messageCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:kAppCharacteristicMessage]
                                                                properties:CBCharacteristicPropertyRead
                                                                     value:[[Settings testMessage] dataUsingEncoding:NSUTF8StringEncoding]
                                                               permissions:CBAttributePermissionsReadable];
    _imageCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:kAppCharacteristicImage]
                                                              properties:CBCharacteristicPropertyNotify
                                                                   value:nil
                                                             permissions:CBAttributePermissionsReadable];
    _initiateConnectionCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:kAppCharacteristicInitiateConnection]
                                                                           properties:CBCharacteristicPropertyWriteWithoutResponse
                                                                                value:nil
                                                                          permissions:CBAttributePermissionsWriteable];
    CBMutableService *_peripheralService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:kAppServiceUUID] primary:YES];
    _peripheralService.characteristics = @[_imageCharacteristic, _messageCharacteristic, _initiateConnectionCharacteristic];
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
        [Log success:[NSString stringWithFormat:@"К данным предоставлен общий доступ. Можно подключаться. Размер пакета %d байт", _mtu]];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    if ([characteristic.UUID.UUIDString isEqualToString:kAppCharacteristicImage]) {
        _imageSendingState = SIZE_SENDING;
        _imagePacketPosition = 0;
        [self sendData];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    if ([characteristic.UUID.UUIDString isEqualToString:kAppCharacteristicImage]) {
        _imageSendingState = IDLE;
        _imagePacketPosition = 0;
    }
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    [self sendData];
}

/*
    Дробление картинки на порции и координирование отправки.
    Идея взята отсюда: http://stackoverflow.com/questions/18476335/sending-image-file-over-bluetooth-4-0-le
 */

- (void)sendData {
    if (_imageSendingState == SIZE_SENDING) {
        [self sendSizeDate];
    }

    else if (_imageSendingState == DATA_SENDING) {
        [self sendImageData];
    }
}

- (void)sendSizeDate {
    NSData *data = [@(_imageData.length).stringValue dataUsingEncoding:NSUTF8StringEncoding];
    BOOL success = [self.peripheralManager updateValue:data forCharacteristic:_imageCharacteristic onSubscribedCentrals:nil];
    if (success) {
        _imageSendingState = DATA_SENDING;
        [self sendImageData];
    }
}

- (void)sendImageData {
    int packetSize = _imageData.length - _imagePacketPosition;

    if (packetSize > _mtu) {
        packetSize = _mtu;
    }

    NSData *packet = [_imageData subdataWithRange:NSMakeRange((NSUInteger) _imagePacketPosition, (NSUInteger) packetSize)];
    BOOL success = [self.peripheralManager updateValue:packet forCharacteristic:_imageCharacteristic onSubscribedCentrals:nil];

    if (success) {
        _imagePacketPosition += packetSize;
        if (_imagePacketPosition >= _imageData.length) {
            [Log success:[NSString stringWithFormat:@"Передача завершена. Передано %d байт", _imageData.length]];
            _imageSendingState = IDLE;
            _imagePacketPosition = 0;
        }
        [self sendData];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
    [self.delegate transferRequestInitiated];
}

@end