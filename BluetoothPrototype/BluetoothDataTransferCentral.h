//
// Created by Евгений Сафронов on 27.08.14.
// Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol BluetoothCentralDelegate

- (void)showImage:(UIImage *)image message:(NSString *)message;

- (void)updateLoadingStatus:(NSInteger)currentStatus maxValue:(NSInteger)maxValue;

@end



@interface BluetoothDataTransferCentral : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

- (void)startScanForDevices;

- (void)stopScanForDevices;

@property id <BluetoothCentralDelegate> delegate;

@end