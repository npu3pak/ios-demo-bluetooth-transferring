//
//  Log.h
//  BluetoothPrototype
//
//  Created by Евгений Сафронов on 24.08.14.
//  Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Log : NSObject

@property NSMutableAttributedString *log;

+ (void)error:(NSString *)message;

+ (void)success:(NSString *)message;

+ (void)message:(NSString *)message;

+ (void)clear;

+ (NSAttributedString *)log;

+ (Log *)instance;

@property SEL onLogChangedCallback;
@property id logChangesListener;

@end
