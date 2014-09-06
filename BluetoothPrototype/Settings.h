//
// Created by Евгений Сафронов on 25.08.14.
// Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Settings : NSObject

+ (UIImage *)testImage;

+ (void)setTestImage:(UIImage *)image;

+ (NSString *)testMessage;

+ (void)setTestMessage:(NSString *)message;

+ (NSUInteger)testImageSize;

+ (NSUInteger)defaultTestImageSize;

+ (void)setMtu:(NSInteger)mtu;

+ (NSInteger)mtu;

@end