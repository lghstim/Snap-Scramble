//
//  CameraViewController.m
//  Snap Scramble
//
//  Created by Tim Gorer on 7/23/16.
//  Copyright © 2016 Tim Gorer. All rights reserved.
//

#import "CameraViewController.h"
#import "PreviewPuzzleViewController.h"
#import "ViewUtils.h"
#import "JPSVolumeButtonHandler.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Masonry/Masonry.h>
#import "ChallengeViewController.h"
#import "SettingsViewController.h"
#import "AppDelegate.h"
#import "CreatePuzzleViewController.h"




@interface CameraViewController ()
@property (strong, nonatomic) LLSimpleCamera *camera;
@property (strong, nonatomic) UILabel *errorLabel;
@property (strong, nonatomic) UIButton *snapButton;
@property (strong, nonatomic) UIButton *switchButton;
@property (strong, nonatomic) UIButton *flashButton;
@property (strong, nonatomic) UISegmentedControl *segmentedControl;
@end

@implementation CameraViewController

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
  
    }
    
    return self;
}

# pragma mark - view methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    self.backButton = [UIButton new];
    [self.backButton addTarget:self action:@selector(backButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.backButton setImage:[UIImage imageNamed:@"icon-back"] forState:UIControlStateNormal];
    self.backButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.backButton.titleLabel.minimumScaleFactor = 0.5;
    [self.view addSubview:self.backButton];
    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.and.width.equalTo(@44);
        make.left.equalTo(self.view).offset(8.f);
        make.bottom.equalTo(self.view).offset(-28.f);
    }];
    self.backButton.adjustsImageWhenHighlighted = YES;
    [self.view bringSubviewToFront:self.backButton];
    
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    // ----- initialize camera -------- //
    
    // create camera vc
    self.camera = [[LLSimpleCamera alloc] initWithQuality:AVCaptureSessionPresetHigh
                                                 position:LLCameraPositionRear
                                             videoEnabled:NO];
    
    // attach to a view controller
    [self.camera attachToViewController:self withFrame:CGRectMake(0, 0, screenRect.size.width, screenRect.size.height)];
    
    // read: http://stackoverflow.com/questions/5427656/ios-uiimagepickercontroller-result-image-orientation-after-upload
    // you probably will want to set this to YES, if you are going view the image outside iOS.
    self.camera.fixOrientationAfterCapture = NO;
    
    // take the required actions on a device change
    __weak typeof(self) weakSelf = self;
    [self.camera setOnDeviceChange:^(LLSimpleCamera *camera, AVCaptureDevice * device) {
        
        NSLog(@"Device changed.");
        
        // device changed, check if flash is available
        if([camera isFlashAvailable]) {
            weakSelf.flashButton.hidden = NO;
            
            if(camera.flash == LLCameraFlashOff) {
                weakSelf.flashButton.selected = NO;
            }
            else {
                weakSelf.flashButton.selected = YES;
            }
        }
        else {
            weakSelf.flashButton.hidden = YES;
        }
    }];
    
    [self.camera setOnError:^(LLSimpleCamera *camera, NSError *error) {
        NSLog(@"Camera error: %@", error);
        
        if([error.domain isEqualToString:LLSimpleCameraErrorDomain]) {
            if(error.code == LLSimpleCameraErrorCodeCameraPermission ||
               error.code == LLSimpleCameraErrorCodeMicrophonePermission) {
                
                if(weakSelf.errorLabel) {
                    [weakSelf.errorLabel removeFromSuperview];
                }
                
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
                label.text = @"We need permission for the camera.\nPlease go to your settings.";
                label.numberOfLines = 2;
                label.lineBreakMode = NSLineBreakByWordWrapping;
                label.backgroundColor = [UIColor clearColor];
                label.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:13.0f];
                label.textColor = [UIColor whiteColor];
                label.textAlignment = NSTextAlignmentCenter;
                [label sizeToFit];
                label.center = CGPointMake(screenRect.size.width / 2.0f, screenRect.size.height / 2.0f);
                weakSelf.errorLabel = label;
                [weakSelf.view addSubview:weakSelf.errorLabel];
            }
        }
    }];
    
    // ----- camera buttons -------- //
    
    // snap button to capture image
    self.snapButton = [[UIButton alloc] init];
    self.snapButton.frame = CGRectMake(0, 0, 70.0f, 70.0f);
    self.snapButton.clipsToBounds = YES;
    self.snapButton.layer.cornerRadius = self.snapButton.frame.size.width / 2.0f;
    self.snapButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.snapButton.layer.borderWidth = 2.0f;
    self.snapButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    self.snapButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.snapButton.layer.shouldRasterize = YES;
    [self.snapButton addTarget:self action:@selector(snapButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.snapButton setImage:[UIImage imageNamed:@"take-photo"] forState:UIControlStateNormal];
    [self.view addSubview:self.snapButton];
    [self.view addSubview:self.backButton]; // back button

    
    // button to toggle flash
    self.flashButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.flashButton.frame = CGRectMake(0, 0, 16.0f + 20.0f, 24.0f + 20.0f);
    self.flashButton.tintColor = [UIColor whiteColor];
    [self.flashButton setImage:[UIImage imageNamed:@"camera-flash"] forState:UIControlStateNormal];
    self.flashButton.imageEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
    [self.flashButton addTarget:self action:@selector(flashButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.flashButton];
    
    if([LLSimpleCamera isFrontCameraAvailable] && [LLSimpleCamera isRearCameraAvailable]) {
        // button to toggle camera positions
        self.switchButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.switchButton.frame = CGRectMake(0, 0, 29.0f + 20.0f, 22.0f + 20.0f);
        self.switchButton.tintColor = [UIColor whiteColor];
        [self.switchButton setImage:[UIImage imageNamed:@"camera-switch"] forState:UIControlStateNormal];
        self.switchButton.imageEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
        [self.switchButton addTarget:self action:@selector(switchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.switchButton];
    }
    
    [self setupDoubleTap]; // for camera
    [self setTopAndBottomButtons];
}

- (void)segmentedControlValueChanged:(UISegmentedControl *)control
{
    NSLog(@"Segment value changed!");
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.snapButton.userInteractionEnabled = TRUE;
    [self.navigationController setNavigationBarHidden:YES animated:NO];

    // start the camera
    [self.camera start];
    
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        NSLog(@"Current user: %@", currentUser.username);
    }
    
    else {
        [self.containerSwipeNavigationController showLeftVCWithSwipeVC:self.containerSwipeNavigationController];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    
    // enable swipe back functionality
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self passDataToCreatePuzzleVC];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}


/* other lifecycle methods */

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    self.camera.view.frame = self.view.contentBounds;
    
    self.snapButton.center = self.view.contentCenter;
    self.snapButton.bottom = self.view.height - 55.0f;
    
    self.flashButton.center = self.view.contentCenter;
    self.flashButton.top = 5.0f;
    
    self.switchButton.top = 5.0f;
    self.switchButton.right = self.view.width - 5.0f;
    
    self.segmentedControl.left = 12.0f;
    self.segmentedControl.bottom = self.view.height - 35.0f;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (void)setTopAndBottomButtons {
    // bottom button
    _bottomButton = [DesignableButton new];
    self.downArrow = [UIImage imageNamed:@"up-arrow"];
    [self.bottomButton setImage:self.downArrow forState:UIControlStateNormal];
    [self.view addSubview:self.bottomButton];
    [self.bottomButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(0);
        CGFloat newWidth = self.downArrow.size.width / 3;
        CGFloat newHeight = self.downArrow.size.height / 3;
        float newWidthInt = (float)newWidth;
        float newHeightInt = (float)newHeight;
        NSNumber *width = [NSNumber numberWithFloat:newWidthInt];
        NSNumber *height = [NSNumber numberWithFloat:newHeightInt];
        make.width.equalTo(width);
        make.height.equalTo(height);
    }];
    [self.view bringSubviewToFront:self.bottomButton];
    [self.bottomButton setImage:[self imageByApplyingAlpha:0.6 andImage:self.downArrow] forState:UIControlStateHighlighted];
    [self.bottomButton addTarget:self action:@selector(showBottomVC) forControlEvents:UIControlEventTouchUpInside];
    
    // top button
    _topButton = [DesignableButton new];
    self.topArrow = [UIImage imageNamed:@"down-arrow"];
    [self.topButton setImage:self.topArrow forState:UIControlStateNormal];
    [self.view addSubview:self.topButton];
    [self.topButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view).offset(0);
        CGFloat newWidth = self.topArrow.size.width / 3;
        CGFloat newHeight = self.topArrow.size.height / 3;
        float newWidthInt = (float)newWidth;
        float newHeightInt = (float)newHeight;
        NSNumber *width = [NSNumber numberWithFloat:newWidthInt];
        NSNumber *height = [NSNumber numberWithFloat:newHeightInt];
        make.width.equalTo(width);
        make.height.equalTo(height);
    }];
    [self.view bringSubviewToFront:self.topButton];
    [self.topButton setImage:[self imageByApplyingAlpha:0.6 andImage:self.topArrow] forState:UIControlStateHighlighted];
    [self.topButton addTarget:self action:@selector(showTopVC) forControlEvents:UIControlEventTouchUpInside];
}

# pragma mark - navigation

- (IBAction)backButtonDidPress:(id)sender {
    [self.containerSwipeNavigationController showLeftVCWithSwipeVC:self.containerSwipeNavigationController];
}

- (void)showLeftVC {
    [self.containerSwipeNavigationController showLeftVCWithSwipeVC:self.containerSwipeNavigationController];
}

- (void)showPreviewPuzzleVC {
    [self performSegueWithIdentifier:@"previewPuzzleSender" sender:self]; // transfer photo to next view controller (PreviewPuzzleViewController)
}

- (void)showBottomVC {
    [self.containerSwipeNavigationController showBottomVCWithSwipeVC:self.containerSwipeNavigationController];
    [self passDataToCreatePuzzleVC];
}

- (void)showTopVC {
    [self.containerSwipeNavigationController showTopVCWithSwipeVC:self.containerSwipeNavigationController];
}

# pragma mark - camera methods logic

/* camera button methods */

- (void)setupDoubleTap {
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(flipCamera)];
    doubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTap];
}

- (void)flipCamera{
    [self.camera togglePosition];
}

- (void)switchButtonPressed:(UIButton *)button
{
    [self.camera togglePosition];
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)flashButtonPressed:(UIButton *)button
{
    if(self.camera.flash == LLCameraFlashOff) {
        BOOL done = [self.camera updateFlashMode:LLCameraFlashOn];
        if(done) {
            self.flashButton.selected = YES;
            self.flashButton.tintColor = [UIColor yellowColor];
        }
    }
    else {
        BOOL done = [self.camera updateFlashMode:LLCameraFlashOff];
        if(done) {
            self.flashButton.selected = NO;
            self.flashButton.tintColor = [UIColor whiteColor];
        }
    }
}

- (void)snapButtonPressed:(UIButton *)button
{
    self.snapButton.userInteractionEnabled = FALSE;
    __weak typeof(self) weakSelf = self;
    
    // capture
    [self.camera capture:^(LLSimpleCamera *camera, UIImage *image, NSDictionary *metadata, NSError *error) {
        if(!error) {
            self.originalImage = image;
            self.cameraImage = image;
            [self showPreviewPuzzleVC];
        }
        else {
            NSLog(@"An error has occured: %@", error);
        }
    } exactSeenImage:YES];
}

# pragma mark - pass data methods

// pass data to PreviewPuzzleVC
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"previewPuzzleSender"]) {
        //[self.volumeButtonHandler stopHandler];
        PreviewPuzzleViewController *previewPuzzleViewController = (PreviewPuzzleViewController *)segue.destinationViewController;
        if ([self.createdGame objectForKey:@"receiverPlayed"] == [NSNumber numberWithBool:true]) { // this is the condition if the game already exists but the receiver has yet to send back. he's already played. not relevant if it's an entirely new game because an entirely new game is made.
            NSLog(@"Game already started: %@", self.createdGame);
            previewPuzzleViewController.createdGame = self.createdGame;
            previewPuzzleViewController.roundObject = self.roundObject;
        }
        
        else if (self.createdGame == nil) {
            NSLog(@"Game hasn't been started yet: %@", self.createdGame);
        }
        
        NSLog(@"imageeee: %@", self.originalImage);
        previewPuzzleViewController.originalImage = self.originalImage;
        previewPuzzleViewController.previewImage = self.cameraImage; // pass the original image for preview since it doesn't need to be resized
        previewPuzzleViewController.opponent = self.opponent;
        NSLog(@"Opponent: %@", self.opponent);
    }
}

- (void)passDataToCreatePuzzleVC {
    CreatePuzzleViewController *createPuzzleVC = (CreatePuzzleViewController*)((AppDelegate *)[UIApplication sharedApplication].delegate).bottomVC;
    createPuzzleVC.opponent = self.opponent;
    createPuzzleVC.createdGame = self.createdGame;
}

- (void)dealloc {
    self.opponent = nil;
    self.createdGame = nil;
    self.roundObject = nil;
    self.originalImage = nil;
    self.cameraImage = nil;
}

# pragma mark - photo editing methods

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

- (UIImage *)imageByApplyingAlpha:(CGFloat) alpha andImage:(UIImage*)image {
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0f);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, image.size.width, image.size.height);
    
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);
    
    CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
    
    CGContextSetAlpha(ctx, alpha);
    
    CGContextDrawImage(ctx, area, [image CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}



@end
