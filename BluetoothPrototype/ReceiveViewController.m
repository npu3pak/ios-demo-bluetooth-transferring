//
//  ReceiveViewController.m
//  BluetoothPrototype
//
//  Created by Евгений Сафронов on 28.08.14.
//  Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "ReceiveViewController.h"
#import "BluetoothCentral.h"
#import "BluetoothPeripheral.h"

@interface ReceiveViewController ()

@end

@implementation ReceiveViewController {
    BluetoothCentral *_central;
    BluetoothPeripheral *_peripheral;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _central = [[BluetoothCentral alloc] init];
    _peripheral = [[BluetoothPeripheral alloc] init];
}

- (IBAction)startSharing:(id)sender {
    [_peripheral setUp];
}

- (IBAction)stopSharing:(id)sender {
    [_peripheral shutDown];
}

- (IBAction)startScan:(id)sender {
    [_central startScanForDevices];
}

- (IBAction)stopScan:(id)sender {
    [_central stopScanForDevices];
}

@end
