//
// Created by Евгений Сафронов on 25.08.14.
// Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import "Settings.h"
#import "Log.h"


static NSString *const kUserDefaultsKeyMessage = @"TestMessage";
static NSString *const kUserDefaultsKeyIsSendingEnabled = @"SendingEnabled";

@implementation Settings

+ (UIImage *)testImage {
    UIImage *image = [UIImage imageWithContentsOfFile:self.testImagePath];
    return image ? image : [UIImage imageNamed:@"HelloWorld.jpg"];
}

+ (void)setTestImage:(UIImage *)image {
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    BOOL imageWriteSuccess = [imageData writeToFile:self.testImagePath atomically:YES];
    if (imageWriteSuccess)
        [Log message:@"Тестовая картинка была обновлена"];
    else
        [Log error:@"Не удалось обновить тестовую картинку"];
}

+ (NSString *)testImagePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:@"TestFile.jpg"];
    return filePath;
}

+ (NSUInteger)testImageSize {
    NSData *data = [NSData dataWithContentsOfFile:[self testImagePath]];
    return data.length ? data.length : self.defaultTestImageSize;
}

+ (NSUInteger)defaultTestImageSize {
    return UIImageJPEGRepresentation([self testImage], 1.0).length;
}

+ (NSString *)testMessage {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *testMessage = [userDefaults stringForKey:kUserDefaultsKeyMessage];
    return testMessage ? testMessage : @"Привет!";
}

+ (void)setTestMessage:(NSString *)message {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:message forKey:kUserDefaultsKeyMessage];
    [userDefaults synchronize];
    [Log message:[NSString stringWithFormat:@"Установлено новое тестовое сообщение: %@", message]];
}

+ (BOOL)sendingEnabled {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:kUserDefaultsKeyIsSendingEnabled];
}

+ (void)setSendingEnabled:(BOOL)sendingEnabled {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:sendingEnabled forKey:kUserDefaultsKeyIsSendingEnabled];
    [userDefaults synchronize];
}

@end