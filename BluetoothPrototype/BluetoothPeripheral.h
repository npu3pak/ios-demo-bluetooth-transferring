//
// Created by Евгений Сафронов on 28.08.14.
// Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BluetoothPeripheral : NSObject <CBPeripheralManagerDelegate>

- (void)setUp;

- (void)shutDown;

@end