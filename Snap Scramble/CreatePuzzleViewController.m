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

@interface CreatePuzzleViewController ()

@end

@implementation CreatePuzzleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [self colorWithHexString:@"71C7F0"];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.clipsToBounds = TRUE;
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.delegate = self;
    self.imagePicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeImage, nil];
    
    [self.takePhotoButton addTarget:self action:@selector(takePhoto:) forControlEvents:UIControlEventTouchUpInside];
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

- (IBAction)takePhoto:(id)sender {
    // takes the user to the next view controller so he can take the photo (CameraViewController)
    [self performSegueWithIdentifier:@"openCamera" sender:self];
}

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

#pragma mark - Image Picker Controller delegate

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

- (void)passDataToCameraVC {
    [self.containerSwipeNavigationController showCenterVCWithSwipeVC:self.containerSwipeNavigationController]; // CameraVC
    CameraViewController *cameraVC = (CameraViewController*)self.containerSwipeNavigationController.centerViewController;
  
    
    if ([self.createdGame objectForKey:@"receiverPlayed"] == [NSNumber numberWithBool:true]) { // this is the condition if the game already exists but the receiver has yet to send back. he's already played. not relevant if it's an entirely new game.
        NSLog(@"Game already started: %@", self.createdGame);
        cameraVC.createdGame = self.createdGame;
        cameraVC.roundObject = self.roundObject;
    }
    
    else if (self.createdGame == nil) { // entirely new game
        NSLog(@"Game hasn't been started yet: %@", self.createdGame);
        
    }
    
    PFQuery* query = [PFUser query];
    [query whereKey:@"username" equalTo:@"mickey"];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        cameraVC.opponent = self.opponent;
        cameraVC.originalImage = self.originalImage;
        cameraVC.createdGame = self.createdGame;
        NSLog(@"Opponent: %@", self.opponent);
        [cameraVC performSegueWithIdentifier:@"previewPuzzleSender" sender:cameraVC];
    }];

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"previewPuzzleSender"]) {
        PreviewPuzzleViewController *previewPuzzleViewController = (PreviewPuzzleViewController *)segue.destinationViewController;
        if ([self.createdGame objectForKey:@"receiverPlayed"] == [NSNumber numberWithBool:true]) { // this is the condition if the game already exists but the receiver has yet to send back. he's already played. not relevant if it's an entirely new game.
            NSLog(@"Game already started: %@", self.createdGame);
            previewPuzzleViewController.createdGame = self.createdGame;
            previewPuzzleViewController.roundObject = self.roundObject;
        }
        
        else if (self.createdGame == nil) { // entirely new game
            NSLog(@"Game hasn't been started yet: %@", self.createdGame);
            
        }
        
        previewPuzzleViewController.opponent = self.opponent;
        previewPuzzleViewController.originalImage = self.originalImage;
        NSLog(@"Opponent: %@", self.opponent);
    }
    
    else if ([segue.identifier isEqualToString:@"openCamera"]) {
        CameraViewController *cameraViewController = (CameraViewController *)segue.destinationViewController;
        if ([self.createdGame objectForKey:@"receiverPlayed"] == [NSNumber numberWithBool:true]) { // this is the condition if the game already exists but the receiver has yet to send back. he's already played. not relevant if it's an entirely new game because an entirely new game is made.
            NSLog(@"Game already started: %@", self.createdGame);
            cameraViewController.createdGame = self.createdGame;
            cameraViewController.roundObject = self.roundObject;
        }
        
        else if (self.createdGame == nil) { // entirely new game
            NSLog(@"Game hasn't been started yet: %@", self.createdGame);
            
        }
        
        NSLog(@"Opponent: %@", self.opponent);
        cameraViewController.opponent = self.opponent;
    }
}


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
