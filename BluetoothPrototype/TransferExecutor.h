//
// Created by Евгений Сафронов on 01.09.14.
// Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class TransferTask;


@interface TransferExecutor : NSObject <CBPeripheralDelegate>

- (void)execute:(TransferTask *)task sender:(id)sender callback:(SEL)callback;

@property BOOL isIdle;

@end