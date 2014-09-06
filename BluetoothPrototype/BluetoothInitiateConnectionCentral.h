//
// Created by Евгений Сафронов on 06.09.14.
// Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>


@interface BluetoothInitiateConnectionCentral : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

- (void)initiateConnection;

@end