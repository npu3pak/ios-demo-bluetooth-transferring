//
// Created by Евгений Сафронов on 01.09.14.
// Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import "TransferTaskManager.h"
#import "TransferTask.h"
#import "TransferExecutor.h"
#import "TransferResult.h"
#import "Log.h"


static const int kMaxConnectionsCount = 1;

@implementation TransferTaskManager

- (id)init {
    self = [super init];
    if (self) {
        self.executors = [NSMutableArray new];
        self.tasks = [NSMutableArray new];
        self.results = [NSMutableArray new];
    }

    return self;
}


+ (TransferTaskManager *)instance {
    static TransferTaskManager *_instance = nil;

    @synchronized (self) {
        if (!_instance)
            _instance = [[TransferTaskManager alloc] init];
    }
    return _instance;
}

- (void)addTask:(TransferTask *)task {

    if (self.executors.count < kMaxConnectionsCount) {
        TransferExecutor *executor = [TransferExecutor new];
        [self.executors addObject:executor];
        [self.executors.lastObject execute:task sender:self callback:@selector(addTransferResult:executor:)];
    } else
        [self.tasks addObject:task];
}

- (void)executeFirstTask:(TransferExecutor *)executor {
    TransferTask *task = self.tasks.firstObject;
    [executor execute:task sender:self callback:@selector(addTransferResult:executor:)];
    [self.tasks removeObject:task];
}

- (void)addTransferResult:(TransferResult *)result executor:(TransferExecutor *)executor {
    if (result)
        [self.results addObject:result];
    if (self.tasks.count)//Есл задания есть - берем первое попавшееся
        [self executeFirstTask:executor];
    else {
        executor.isIdle = YES;

        BOOL isFinished = YES;
        for (TransferExecutor *e in self.executors)
            if (!e.isIdle)
                isFinished = NO;

        if (isFinished)
            [self finishTransfers];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (void)finishTransfers {
    [Log success:@"Завершен обмен данными с устройством"];
    if (self.results.count) {
        for (TransferResult *result in self.results) {
            id o = result.task.sender;
            if ([o respondsToSelector:@selector(performSelector:withObject:)]) {
                [o performSelector:result.task.callback withObject:result];
            }
        }
    }
    self.results = [NSMutableArray new];
}
#pragma clang diagnostic pop

@end