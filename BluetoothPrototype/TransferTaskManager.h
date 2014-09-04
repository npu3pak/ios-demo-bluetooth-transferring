//
// Created by Евгений Сафронов on 01.09.14.
// Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TransferTask;


@interface TransferTaskManager : NSObject

@property NSMutableArray *tasks;
@property NSMutableArray *executors;
@property NSMutableArray *results;


+ (TransferTaskManager *)instance;

- (void)addTask:(TransferTask *)task;

@end