//
//  Log.m
//  BluetoothPrototype
//
//  Created by Евгений Сафронов on 24.08.14.
//  Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import "Log.h"


@interface Log ()

@property(nonatomic, strong) NSDateFormatter *dateFormat;

@end

@implementation Log

- (id)init {
    self = [super init];
    if (self) {
        self.log = [[NSMutableAttributedString alloc] initWithString:@""];

        self.dateFormat = [[NSDateFormatter alloc] init];
        [self.dateFormat setDateFormat:@"HH:mm:ss:SSS"];
    }
    return self;
}


+ (Log *)instance {
    static Log *_instance = nil;

    @synchronized (self) {
        if (!_instance)
            _instance = [[Log alloc] init];
    }
    return _instance;
}

+ (void)error:(NSString *)message {
    [self writeMessage:message color:[UIColor redColor]];
}

+ (void)success:(NSString *)message {
    [self writeMessage:message color:[UIColor greenColor]];
}

+ (void)message:(NSString *)message {
    [self writeMessage:message color:nil];
}

+ (void)clear {
    self.instance.log = [NSMutableAttributedString new];
}

+ (NSAttributedString *)log {
    return self.instance.log;
}

+ (void)writeMessage:(NSString *)message color:(UIColor *)color {
    NSString *record = [NSString stringWithFormat:@"%@\n%@\n\n", [self timeStamp], message];
    NSMutableAttributedString *attributedRecord = [[NSMutableAttributedString alloc] initWithString:record];

    if (color){
        [attributedRecord addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, attributedRecord.length)];
    }

    [self.instance.log insertAttributedString:attributedRecord atIndex:0];
    [self updateJournal];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
+ (void)updateJournal {
    if (self.instance.logChangesListener && self.instance.onLogChangedCallback) {
        @synchronized ([self instance].logChangesListener) {
            [self.instance.logChangesListener performSelector:self.instance.onLogChangedCallback];
        }
    }
}
#pragma clang diagnostic pop

+ (NSString *)timeStamp {
    return [self.instance.dateFormat stringFromDate:[NSDate date]];
}

@end
