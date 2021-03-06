//
//  CreatePuzzleViewController.m
//  Snap Scramble
//
//  Created by Tim Gorer on 7/20/15.
//  Copyright (c) 2015 Tim Gorer. All rights reserved.
//

#import "CreatePuzzleViewController.h"
#import "PreviewPuzzleViewController.h"
#import "GameViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "ChallengeViewController.h"
#import "CameraViewController.h"
#import "AppDelegate.h"
@import SwipeNavigationController;


@interface CreatePuzzleViewController ()

@end

@implementation CreatePuzzleViewController

# pragma mark - view methods

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [self colorWithHexString:@"71C7F0"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.clipsToBounds = TRUE;
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.navigationBar.tintColor = [self colorWithHexString:@"FFFFFF"];
    self.imagePicker.navigationBar.backgroundColor = [self colorWithHexString:@"71C7F0"];
    self.imagePicker.navigationBar.barTintColor = [self colorWithHexString:@"71C7F0"];
    self.imagePicker.delegate = self;
    self.imagePicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeImage, nil];
    
    [self.choosePhotoButton addTarget:self action:@selector(choosePhoto:) forControlEvents:UIControlEventTouchUpInside];
    [self.backButton addTarget:self action:@selector(backButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
    self.backButton.adjustsImageWhenHighlighted = YES;
    self.takePhotoButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.takePhotoButton.titleLabel.minimumScaleFactor = 0.5;
    self.choosePhotoButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.choosePhotoButton.titleLabel.minimumScaleFactor = 0.5;
    self.createPuzzleLabel.adjustsFontSizeToFitWidth = YES;
    self.createPuzzleLabel.minimumScaleFactor = 0.5;
    self.opponentLabel.adjustsFontSizeToFitWidth = YES;
    self.opponentLabel.minimumScaleFactor = 0.5;
    
    // set opponent label
    self.opponentLabel.text = [NSString stringWithFormat:@"Opponent: %@", self.opponent.username];
}

# pragma mark - navigation

- (IBAction)choosePhoto:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:self.imagePicker animated:NO completion:nil];
    }
    
    else {
        NSLog(@"Photo library not available.");
    }
}

- (IBAction)backButtonDidPress:(id)sender {
    [self.containerSwipeNavigationController showCenterVCWithSwipeVC:self.containerSwipeNavigationController];
}

#pragma mark - image picker controller delegate logic

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:NO completion:nil];
    
    //This for loop iterates through all the view controllers in navigation stack.
    for (UIViewController* viewController in self.navigationController.viewControllers) {
        
        //This if condition checks whether the viewController's class is a CreatePuzzleViewController
        // if true that means its the FriendsViewController (which has been pushed at some point)
        if ([viewController isKindOfClass:[CreatePuzzleViewController class]] ) {
            
            // Here viewController is a reference of UIViewController base class of CreatePuzzleViewController
            // but viewController holds CreatePuzzleViewController  object so we can type cast it here
            CreatePuzzleViewController *createPuzzleViewController = (CreatePuzzleViewController *)viewController;
            [self.navigationController popToViewController:createPuzzleViewController animated:YES];
        }
    }
}

# pragma mark - pass data methods

- (void)passDataToCameraVC {
    CameraViewController *cameraVC = (CameraViewController*)((AppDelegate *)[UIApplication sharedApplication].delegate).centerVC;
    NSLog(@"cam vc: %@", cameraVC);
    
    NSLog(@"Opponent: %@", self.opponent);
    cameraVC.opponent = self.opponent;
    cameraVC.createdGame = self.createdGame;

    if ([self.createdGame objectForKey:@"receiverPlayed"] == [NSNumber numberWithBool:true]) { // this is the condition if the game already exists but the receiver has yet to send back. he's already played. not relevant if it's an entirely new game.
        NSLog(@"Game already started: %@", self.createdGame);
        cameraVC.roundObject = self.roundObject;
        cameraVC.opponent = self.opponent;
    }
    
    else if (self.createdGame == nil) { // entirely new game
        NSLog(@"Game hasn't been started yet: %@", self.createdGame);
    }
    
    NSLog(@"image CPVC: %@", self.originalImage);
    cameraVC.originalImage = self.originalImage;
    cameraVC.createdGame = self.createdGame;
    [self.containerSwipeNavigationController showCenterVCWithSwipeVC:self.containerSwipeNavigationController]; // CameraVC
    [cameraVC performSegueWithIdentifier:@"previewPuzzleSender" sender:cameraVC];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
}

- (void)deallocate{
    self.opponent = nil;
    self.createdGame = nil;
    self.roundObject = nil;
}

# pragma mark - photo editing methods

// this is for resizing an image that is selected from the photo library
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {   // A photo was taken or selected
        UIImage* tempOriginalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        self.originalImage = tempOriginalImage;
        NSLog(@"original image: %@", self.originalImage);
        NSLog(@"Screen Width: %f    Screen Height: %f", self.view.frame.size.width, self.view.frame.size.height);
        [self dismissViewControllerAnimated:YES completion:nil]; // dismiss photo picker
        [self passDataToCameraVC];
    }
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToFillSize:(CGSize)size
{
    CGFloat scale = MAX(size.width/image.size.width, size.height/image.size.height);
    CGFloat width = image.size.width * scale;
    CGFloat height = image.size.height * scale;
    CGRect imageRect = CGRectMake((size.width - width)/2.0f,
                                  (size.height - height)/2.0f,
                                  width,
                                  height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    [image drawInRect:imageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)resizeImage:(UIImage *)image withMaxDimension:(CGFloat)maxDimension {
    if (fmax(image.size.width, image.size.height) <= maxDimension) {
        return image;
    }
    
    CGFloat aspect = image.size.width / image.size.height;
    CGSize newSize;
    
    if (image.size.width > image.size.height) {
        newSize = CGSizeMake(maxDimension, maxDimension / aspect);
    } else {
        newSize = CGSizeMake(maxDimension * aspect, maxDimension);
    }
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
    CGRect newImageRect = CGRectMake(0.0, 0.0, newSize.width, newSize.height);
    [image drawInRect:newImageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

# pragma mark - other methods

// create a hex color
-(UIColor*)colorWithHexString:(NSString*)hex {
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) return [UIColor grayColor];
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    
    if ([cString length] != 6) return  [UIColor grayColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0f];
}



@end
