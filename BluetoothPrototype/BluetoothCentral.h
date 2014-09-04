//
// Created by Евгений Сафронов on 27.08.14.
// Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BluetoothCentral : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

- (void)startScanForDevices;

- (void)stopScanForDevices;
@end