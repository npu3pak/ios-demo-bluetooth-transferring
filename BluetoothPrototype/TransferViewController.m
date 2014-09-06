//
//  TransferViewController.m
//  BluetoothPrototype
//
//  Created by Евгений Сафронов on 28.08.14.
//  Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "TransferViewController.h"
#import "ResultViewController.h"
#import "BluetoothInitiateConnectionCentral.h"

@interface TransferViewController ()

@property(weak, nonatomic) IBOutlet UISwitch *peripheralStateSwitch;
@property(weak, nonatomic) IBOutlet UIProgressView *loadingProgressView;
@property(weak, nonatomic) IBOutlet UIButton *startLoadingButton;
@property(weak, nonatomic) IBOutlet UIButton *stopLoadingButton;
@property(weak, nonatomic) IBOutlet UIButton *initiateTransferButton;

@end

@implementation TransferViewController {
    BluetoothDataTransferCentral *_central;
    BluetoothInitiateConnectionCentral *_initiatorCentral;
    BluetoothPeripheral *_peripheral;

    UIImage *_resultImage;
    NSString *_resultMessage;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _peripheral = [[BluetoothPeripheral alloc] initWithSender:self
                                    peripheralStartedCallback:@selector(onPeripheralEnabled)
                                    peripheralStoppedCallback:@selector(onPeripheralDisabled)];
    _peripheral.delegate = self;

    _central = [[BluetoothDataTransferCentral alloc] init];
    _central.delegate = self;

    _initiatorCentral = [[BluetoothInitiateConnectionCentral alloc] init];

    [self showLoadButton];
    self.initiateTransferButton.hidden = YES;
}

- (void)showLoadButton {
    self.startLoadingButton.hidden = NO;
    self.stopLoadingButton.hidden = YES;
    self.loadingProgressView.hidden = YES;
}

- (IBAction)peripheralSwitchStateChanged:(UISwitch *)sender {
    if (sender.on) {
        [_peripheral setUp];
        self.initiateTransferButton.hidden = NO;
    }
    else {
        [_peripheral shutDown];
        self.initiateTransferButton.hidden = YES;
    }
}

- (void)onPeripheralDisabled {
    self.peripheralStateSwitch.on = NO;
    self.initiateTransferButton.hidden = YES;
}

- (void)onPeripheralEnabled {
    self.peripheralStateSwitch.on = YES;
    self.initiateTransferButton.hidden = NO;
}

- (IBAction)startScan:(id)sender {
    self.startLoadingButton.hidden = YES;
    self.stopLoadingButton.hidden = NO;
    [_central startScanForDevices];
}

- (IBAction)stopScan:(id)sender {
    [self showCancelButton];
    [_central stopScanForDevices];
}

- (void)showCancelButton {
    self.startLoadingButton.hidden = NO;
    self.stopLoadingButton.hidden = YES;
    self.loadingProgressView.hidden = YES;
}

- (void)updateLoadingStatus:(NSInteger)currentStatus maxValue:(NSInteger)maxValue {
    self.loadingProgressView.hidden = NO;
    self.loadingProgressView.progress = (float) currentStatus / (float) maxValue;
}

- (void)showImage:(UIImage *)image message:(NSString *)message {
    [self showLoadButton];
    _resultImage = image;
    _resultMessage = message;
    [self performSegueWithIdentifier:@"showTransferResult" sender:self];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showTransferResult"]) {
        ResultViewController *resultViewController = segue.destinationViewController;
        resultViewController.message = _resultMessage;
        resultViewController.image = _resultImage;
    }
}

- (IBAction)initiateTransfer:(id)sender {
    [_initiatorCentral initiateConnection];
}

- (void)transferRequestInitiated {
    [self showLoadButton];
    [self stopScan:nil];
    [self startScan:nil];
}


@end
