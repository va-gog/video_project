//
//  ChooseVideoViewController.m
//  VideoProjectI
//
//  Created by Gohar Vardanyan on 8/6/18.
//  Copyright © 2018 Gohar Vardanyan. All rights reserved.
//

#import "ChooseVideoViewController.h"
#import <AVKit/AVKit.h>
#import "AddStickersViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "CALayer+Additions.h"

@interface ChooseVideoViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@end

@implementation ChooseVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController.navigationBar setHidden:YES];
}

- (IBAction)chooseVideoAction:(UIButton *)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
        UIImagePickerController *imagePickerController = [[UIImagePickerController  alloc] init];
        imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        imagePickerController.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, nil];
        imagePickerController.delegate = self;
        imagePickerController.allowsEditing = YES;
        [self presentViewController:imagePickerController animated:YES completion:nil];
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [self dismissViewControllerAnimated:YES completion:^{
        [self performSegueWithIdentifier:@"DisplayStickerViewController" sender:info[UIImagePickerControllerMediaURL]];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    assert([sender isKindOfClass:[NSURL class]]);
    if ([segue.identifier isEqualToString:@"DisplayStickerViewController"]){
        AddStickersViewController *vc = (AddStickersViewController *)[segue destinationViewController];
        vc.chosenVideoURL = sender;
    } else {
        assert(0);
    }
}

@end
