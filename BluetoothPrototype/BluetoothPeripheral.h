//
// Created by Евгений Сафронов on 28.08.14.
// Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BluetoothPeripheralDelegate

- (void)dataLoadingInitiated;

- (void)uploadingCancelled;

- (void)updateUploadingStatus:(NSInteger)currentStatus maxValue:(NSInteger)maxValue;
@end

@interface BluetoothPeripheral : NSObject <CBPeripheralManagerDelegate>
- (instancetype)initWithSender:(id)sender peripheralStartedCallback:(SEL)peripheralStartedCallback peripheralStoppedCallback:(SEL)peripheralStoppedCallback;

- (void)setUp;

- (void)shutDown;

@property id <BluetoothPeripheralDelegate> delegate;

@end