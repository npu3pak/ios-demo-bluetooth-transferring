//
// Created by Евгений Сафронов on 01.09.14.
// Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "TransferTask.h"


@implementation TransferTask {

}
- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral sender:(id)sender callback:(SEL)callback {
    self = [super init];
    if (self) {
        self.peripheral = peripheral;
        self.sender = sender;
        self.callback = callback;
    }

    return self;
}

@end