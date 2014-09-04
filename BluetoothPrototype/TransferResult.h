//
// Created by Евгений Сафронов on 01.09.14.
// Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TransferTask;


@interface TransferResult : NSObject

@property NSData *imageData;
@property NSData *messageData;
@property TransferTask *task;

- (instancetype)initWithImageData:(NSData *)imageData messageData:(NSData *)messageData task:(TransferTask *)task;

@end