//
//  TransferViewController.h
//  BluetoothPrototype
//
//  Created by Евгений Сафронов on 28.08.14.
//  Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BluetoothDataTransferCentral.h"
#import "BluetoothPeripheral.h"

@interface TransferViewController : UIViewController <BluetoothCentralDelegate, BluetoothPeripheralDelegate>


@end
