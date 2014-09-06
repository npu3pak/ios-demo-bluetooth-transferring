//
// Created by Евгений Сафронов on 06.09.14.
// Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import "ResultViewController.h"

@interface ResultViewController ()

@property(weak, nonatomic) IBOutlet UIImageView *imageView;
@property(weak, nonatomic) IBOutlet UILabel *label;

@end


@implementation ResultViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.imageView.image = self.image;
    self.label.text = self.message;
}

@end