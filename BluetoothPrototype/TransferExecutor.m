//
// Created by Евгений Сафронов on 01.09.14.
// Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import "TransferExecutor.h"
#import "TransferTask.h"
#import "TransferResult.h"
#import "Constants.h"
#import "Log.h"

@implementation TransferExecutor {
    id _sender;
    SEL _callback;
    TransferTask *_task;

    NSData *_messageData;
    NSData *_imageData;

}

- (void)execute:(TransferTask *)task sender:(id)sender callback:(SEL)callback {
    self.isIdle = NO;
    _sender = sender;
    _callback = callback;
    _task = task;
    _messageData = nil;
    _imageData = nil;
    [self executeTask];
}

- (void)executeTask {
    _task.peripheral.delegate = self;
    [_task.peripheral discoverServices:@[[CBUUID UUIDWithString:kAppServiceUUID]]];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        [Log error:[NSString stringWithFormat:@"Ошибка подключения к сервису: %@", error.localizedDescription]];
    }
    else {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kAppCharacteristicImage]]
                                 forService:peripheral.services[0]];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        [Log error:[NSString stringWithFormat:@"Ошибка получение характеристик: %@", error.localizedDescription]];
    }
    else {
        for (CBCharacteristic *characteristic in service.characteristics) {
            [peripheral readValueForCharacteristic:characteristic];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        [Log error:[NSString stringWithFormat:@"Ошибка получение значения характеристики: %@", error.localizedDescription]];
    }
    if ([characteristic.UUID.UUIDString isEqualToString:kAppCharacteristicImage]) {
        _imageData = characteristic.value;
    }

    if (_imageData && _messageData) {
        [Log message:[NSString stringWithFormat:@"Размер картинки %d", _imageData.length]];
//        [self endTransfer];
    }
}


- (void)endTransfer {
    if ([_sender respondsToSelector:@selector(performSelector:withObject:withObject:)]) {
        TransferResult *result = [[TransferResult alloc] initWithImageData:_imageData messageData:_messageData task:_task];
        [_sender performSelector:_callback withObject:result withObject:self];
    }
}

@end