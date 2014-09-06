//
//  SettingsTableViewController.m
//  BluetoothPrototype
//
//  Created by Евгений Сафронов on 24.08.14.
//  Copyright (c) 2014 Евгений Сафронов. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "Settings.h"
#import "UIImage+Resize.h"
#import "Log.h"

@interface SettingsTableViewController ()
@property(weak, nonatomic) IBOutlet UITextField *messageTextField;
@property(weak, nonatomic) IBOutlet UIImageView *testImageView;
@property(weak, nonatomic) IBOutlet UILabel *testImageSizeLabel;
@property(weak, nonatomic) IBOutlet UIStepper *mtuStepper;
@property(weak, nonatomic) IBOutlet UILabel *mtuLabel;

@end

@implementation SettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.messageTextField.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self showSendingData];
}

- (IBAction)mtuStepperValueChanged:(UIStepper *)sender {
    [Settings setMtu:(NSInteger) sender.value];
    [self refreshMtuValue];
}

- (void)showSendingData {
    self.messageTextField.text = [Settings testMessage];
    self.testImageView.image = [Settings testImage];
    self.mtuStepper.value = [Settings mtu];
    [self refreshMtuValue];

    NSString *sizeInKilobytes = @([Settings testImageSize] / 1024).stringValue;
    self.testImageSizeLabel.text = [NSString stringWithFormat:@"%@ Kb", sizeInKilobytes];
}

- (void)refreshMtuValue {
    self.mtuLabel.text = [NSString stringWithFormat:@"%d байт", [Settings mtu]];
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
    if (indexPath.section == 1 && indexPath.row == 0)
        [self selectImage];
    if (indexPath.section == 1 && indexPath.row == 1)
        [self takePhoto];
}

- (void)selectImage {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)takePhoto {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    [Log message:[NSString stringWithFormat:@"Старый размер %fx%f", image.size.width, image.size.height]];
    if (image.size.width > 640 || image.size.height > 480)
        image = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(640, 480) interpolationQuality:kCGInterpolationDefault];
    [Log message:[NSString stringWithFormat:@"Новый размер %fx%f", image.size.width, image.size.height]];
    [Settings setTestImage:image];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
