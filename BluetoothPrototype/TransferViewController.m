//
//  TransferViewController.m
//  BluetoothPrototype
//
//  Created by Евгений Сафронов on 28.08.14.
//  Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "TransferViewController.h"
#import "BluetoothCentral.h"
#import "BluetoothPeripheral.h"

@interface TransferViewController ()

@property(weak, nonatomic) IBOutlet UISwitch *peripheralStateSwitch;

@end

@implementation TransferViewController {
    BluetoothCentral *_central;
    BluetoothPeripheral *_peripheral;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _peripheral = [[BluetoothPeripheral alloc] initWithSender:self
                                    peripheralStartedCallback:@selector(onPeripheralEnabled)
                                    peripheralStoppedCallback:@selector(onPeripheralDisabled)];
    _central = [[BluetoothCentral alloc] init];
}
- (IBAction)peripheralSwitchStateChanged:(UISwitch *)sender {
    if(sender.on)
        [_peripheral setUp];
    else
        [_peripheral shutDown];
}

- (void)onPeripheralDisabled {
    self.peripheralStateSwitch.on = NO;
}

- (void)onPeripheralEnabled {
    self.peripheralStateSwitch.on = YES;
}

- (IBAction)startScan:(id)sender {
    [_central startScanForDevices];
}

- (IBAction)stopScan:(id)sender {
    [_central stopScanForDevices];
}

@end
