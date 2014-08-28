//
//  SendTableViewController.m
//  BluetoothPrototype
//
//  Created by Евгений Сафронов on 24.08.14.
//  Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import "SendTableViewController.h"
#import "Settings.h"

@interface SendTableViewController ()
@property(weak, nonatomic) IBOutlet UITextField *messageTextField;
@property(weak, nonatomic) IBOutlet UIImageView *testImageView;
@property(weak, nonatomic) IBOutlet UILabel *testImageSizeLabel;

@end

@implementation SendTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.messageTextField.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self showSendingData];
}

- (void)showSendingData {
    self.messageTextField.text = [Settings testMessage];
    self.testImageView.image = [Settings testImage];

    NSString *sizeInKilobytes = @([Settings testImageSize] / 1024).stringValue;
    self.testImageSizeLabel.text = [NSString stringWithFormat:@"%@ Kb", sizeInKilobytes];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self hideKeyboard];
    return YES;
}

- (void)hideKeyboard {
    [self.messageTextField resignFirstResponder];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [Settings setTestMessage:textField.text];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        [self selectImage];
    }
}

- (void)selectImage {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    [Settings setTestImage:image];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
