//
//  LogViewController.m
//  BluetoothPrototype
//
//  Created by Евгений Сафронов on 24.08.14.
//  Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import "LogViewController.h"
#import "Log.h"

@interface LogViewController ()

@property(weak, nonatomic) IBOutlet UITextView *logTextView;

@end

@implementation LogViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshLog];
}

- (void)refreshLog {
    self.logTextView.attributedText = [Log log];
}

- (IBAction)clearLog:(id)sender {
    [Log clear];
    [self refreshLog];
}

- (IBAction)sendLog:(id)sender {
    NSString *message = Log.log.string;
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[message] applicationActivities:nil];
    [self presentViewController:activity animated:YES completion:nil];
}

@end
