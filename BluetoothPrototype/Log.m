//
//  Log.m
//  BluetoothPrototype
//
//  Created by Евгений Сафронов on 24.08.14.
//  Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import "Log.h"
#import "AppDelegate.h"

@implementation Log

- (id)init {
    self = [super init];
    if (self) {
        self.log = [[NSMutableAttributedString alloc] initWithString:@""];
    }
    return self;
}


+ (void)error:(NSString *)message {
    [self writeMessage:message color:[UIColor redColor]];
}

+ (void)success:(NSString *)message {
    [self writeMessage:message color:[UIColor greenColor]];
}

+ (void)message:(NSString *)message {
    [self writeMessage:message color:[UIColor blackColor]];
}

+ (void)clear {
    [self instance].log = [NSMutableAttributedString new];
}

+ (NSAttributedString *)log {
    return [self instance].log;
}

+ (void)writeMessage:(NSString *)message color:(UIColor *)color {
    NSString *record = [NSString stringWithFormat:@"%@\n%@\n\n", [self timeStamp], message];
    NSMutableAttributedString *attributedRecord = [[NSMutableAttributedString alloc] initWithString:record];
    [attributedRecord addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, attributedRecord.length)];

    [attributedRecord appendAttributedString:self.instance.log];
    self.instance.log = attributedRecord;
}

+ (NSString *)timeStamp {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"HH:mm:ss:SSS"];
    return [dateFormat stringFromDate:[NSDate date]];
}

+ (Log *)instance {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    return appDelegate.log;
}


@end
