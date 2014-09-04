//
// Created by Евгений Сафронов on 01.09.14.
// Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CBPeripheral;


@interface TransferTask : NSObject

@property CBPeripheral *peripheral;
@property id sender;
@property SEL callback;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral sender:(id)sender callback:(SEL)callback;


@end