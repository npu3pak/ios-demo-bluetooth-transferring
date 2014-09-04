//
// Created by Евгений Сафронов on 01.09.14.
// Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import "TransferResult.h"
#import "TransferTask.h"


@implementation TransferResult {

}

- (instancetype)initWithImageData:(NSData *)imageData messageData:(NSData *)messageData task:(TransferTask *)task {
    self = [super init];
    if (self) {
        self.imageData = imageData;
        self.messageData = messageData;
        self.task = task;
    }

    return self;
}


@end