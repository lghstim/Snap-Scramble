//
//  PreviewPuzzleViewController.m
//  Snap Scramble
//
//  Created by Tim Gorer on 7/20/15.
//  Copyright (c) 2015 Tim Gorer. All rights reserved.
//

#import "PreviewPuzzleViewController.h"
#import "GameViewController.h"
#import "ChallengeViewController.h"
#import "PreviewPuzzleViewModel.h"
@import AssetsLibrary;
#import <Masonry/Masonry.h>
#import <jot/jot.h>
#import "JotViewController.h"
#import <KVNProgress/KVNProgress.h>
#import "UserSelectionViewController.h"


NSString * const kDrawModeActiveImageName = @"draw-button-active";
NSString * const kDrawModeInactiveImageName = @"draw-button-inactive";
NSString * const kTextModeActiveName = @"edit-text-button-active";
NSString * const kTextModeInactiveName = @"edit-text-button-inactive";
NSString * const kClearImageName = @"undo-button";
NSString * const kSaveImageName = @"download-button";

@interface PreviewPuzzleViewController () <JotViewControllerDelegate>

@property (nonatomic, strong) JotViewController *jotViewController;
// @property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) UIButton *clearButton;
@property (nonatomic, strong) UIButton *toggledDrawingButton;
@property (nonatomic, strong) UIButton *untoggledDrawingButton;
@property (nonatomic, strong) UIButton *untoggledTextButton;
@property (nonatomic, strong) UIButton *toggledTextButton;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *saveButton;
@property(nonatomic, strong) PreviewPuzzleViewModel *viewModel;

@end

@implementation PreviewPuzzleViewController

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _viewModel = [[PreviewPuzzleViewModel alloc] init];
        [self setButtonUI];
    }
    
    return self;
}

# pragma mark - view methods

- (void)viewDidLoad {
    [super viewDidLoad];
    self.puzzleSizes = [[NSArray alloc] initWithObjects:@"4 x 4", @"5 x 5", @"6 x 6", nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:true];
    self.imageView = [UIImageView new];
    self.imageView.clipsToBounds = YES;
    self.imageView.layer.cornerRadius = 5.0f;
    self.backButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.backButton.titleLabel.minimumScaleFactor = 0.5;
    self.selectPuzzleSizeButton.titleLabel.adjustsFontSizeToFitWidth = YES;
   self.selectPuzzleSizeButton.titleLabel.minimumScaleFactor = 0.5;

    self.currentUser = [PFUser currentUser];
    
    if (self.originalImage) { // if the image was just created by the player (sender) and is saved in memory, display it
        
        self.view.backgroundColor = [UIColor whiteColor];
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenRect.size.width, screenRect.size.height)];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.backgroundColor = [UIColor clearColor];
        self.previewImage = [self prepareImageForPreview:self.originalImage];
        self.imageView.image = self.previewImage;
        [self.view addSubview:self.imageView];
        self.gameImage = [self prepareImageForGame:self.originalImage]; // now resize image for the game
        
        [self addChildViewController:self.jotViewController];
        [self.view addSubview:self.jotViewController.view];
        
        [self.jotViewController didMoveToParentViewController:self];
        [self.jotViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
        
        
        [self.view addSubview:self.saveButton];
        [self.saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.and.width.equalTo(@44);
            make.right.equalTo(self.view).offset(-8.f);
            make.bottom.equalTo(self.view).offset(-32.f);
        }];
        
        [self.view addSubview:self.clearButton];
        [self.clearButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.and.width.equalTo(@44);
            make.right.equalTo(self.view).offset(-60.f);
            make.top.equalTo(self.view).offset(25.f);
        }];
        self.clearButton.hidden = YES;
   
        [self.view addSubview:self.toggledDrawingButton];
        [self.toggledDrawingButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.and.width.equalTo(@44);
            make.right.equalTo(self.view).offset(-8.f);
            make.top.equalTo(self.view).offset(25.f);
        }];
        self.toggledDrawingButton.hidden = YES; // hide the toggled button at first
        
        [self.view addSubview:self.untoggledDrawingButton];
        [self.untoggledDrawingButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.and.width.equalTo(@44);
            make.right.equalTo(self.view).offset(-8.f);
            make.top.equalTo(self.view).offset(25.f);
        }];
        
        
        [self.view addSubview:self.untoggledTextButton];
        [self.untoggledTextButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.and.width.equalTo(@44);
            make.right.equalTo(self.view).offset(-65.f);
            make.top.equalTo(self.view).offset(25.f);
        }];
        
        [self.view addSubview:self.toggledTextButton];
        [self.toggledTextButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.and.width.equalTo(@44);
            make.right.equalTo(self.view).offset(-65.f);
            make.top.equalTo(self.view).offset(25.f);
        }];
        self.toggledTextButton.hidden = YES;
        
        
        [self.view addSubview:self.backButton];
        [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.and.width.equalTo(@44);
            make.left.equalTo(self.view).offset(8.f);
            make.bottom.equalTo(self.view).offset(-28.f);
        }];
        
        [self.view addSubview:self.selectPuzzleSizeButton];
        [self.selectPuzzleSizeButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@40);
            make.width.equalTo(@200);
            make.centerX.equalTo(self.view);
            make.bottom.equalTo(self.view).offset(-28.f);
        }];

        
        [self.view bringSubviewToFront:self.backButton];
        [self.view bringSubviewToFront:self.selectPuzzleSizeButton];
        [self.view bringSubviewToFront:self.clearButton];
        [self.view bringSubviewToFront:self.toggledDrawingButton];
        [self.view bringSubviewToFront:self.saveButton];
        [self.backButton addTarget:self action:@selector(backButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
        [self.selectPuzzleSizeButton addTarget:self action:@selector(selectPuzzleSizeButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
        self.backButton.adjustsImageWhenHighlighted = YES;
    }
    
    else {
        NSLog(@"Some problem.");
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // disable swipe back functionality
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return NO;
}

- (void)setButtonUI {
    _jotViewController = [JotViewController new];
    self.jotViewController.delegate = self;
    self.jotViewController.textColor =  [UIColor whiteColor];
    self.jotViewController.font = [UIFont boldSystemFontOfSize:64.f];
    self.jotViewController.fontSize = 64.f;
    self.jotViewController.textEditingInsets = UIEdgeInsetsMake(12.f, 6.f, 0.f, 6.f);
    self.jotViewController.initialTextInsets = UIEdgeInsetsMake(6.f, 6.f, 6.f, 6.f);
    self.jotViewController.fitOriginalFontSizeToViewWidth = YES;
    self.jotViewController.textAlignment = NSTextAlignmentLeft;
    self.jotViewController.drawingColor = [self colorWithHexString:@"71C7F0"]; // blue
    
    _saveButton = [UIButton new];
    self.saveButton.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:24.f];
    [self.saveButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.saveButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [self.saveButton setImage:[UIImage imageNamed:kSaveImageName] forState:UIControlStateNormal];
    [self.saveButton addTarget:self
                        action:@selector(saveButtonAction)
              forControlEvents:UIControlEventTouchUpInside];
    
    _clearButton = [UIButton new];
    self.clearButton.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:24.f];
    [self.clearButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.clearButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [self.clearButton setImage:[UIImage imageNamed:kClearImageName] forState:UIControlStateNormal];
    [self.clearButton addTarget:self
                         action:@selector(clearButtonAction)
               forControlEvents:UIControlEventTouchUpInside];
    
    _toggledDrawingButton = [UIButton new];
    self.toggledDrawingButton.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:24.f];
    [self.toggledDrawingButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.toggledDrawingButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [self.toggledDrawingButton setImage:[UIImage imageNamed:kDrawModeActiveImageName] forState:UIControlStateNormal];
    [self.toggledDrawingButton addTarget:self
                                  action:@selector(untoggleDrawingButtonAction)
                        forControlEvents:UIControlEventTouchUpInside];
    
    _untoggledDrawingButton = [UIButton new];
    self.untoggledDrawingButton.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:24.f];
    [self.untoggledDrawingButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.untoggledDrawingButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [self.untoggledDrawingButton setImage:[UIImage imageNamed:kDrawModeInactiveImageName] forState:UIControlStateNormal];
    [self.untoggledDrawingButton addTarget:self
                                    action:@selector(toggleDrawingButtonAction)
                          forControlEvents:UIControlEventTouchUpInside];
    
    
    
    _untoggledTextButton = [UIButton new];
    self.untoggledTextButton.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:24.f];
    [self.untoggledTextButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.untoggledTextButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [self.untoggledTextButton setImage:[UIImage imageNamed:kTextModeInactiveName] forState:UIControlStateNormal];
    [self.untoggledTextButton addTarget:self
                                 action:@selector(toggleTextButtonAction)
                       forControlEvents:UIControlEventTouchUpInside];
    
    _toggledTextButton = [UIButton new];
    self.toggledTextButton.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:24.f];
    [self.toggledTextButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.toggledTextButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [self.toggledTextButton setImage:[UIImage imageNamed:kTextModeActiveName] forState:UIControlStateNormal];
    [self.toggledTextButton addTarget:self
                               action:@selector(untoggleTextButtonAction)
                     forControlEvents:UIControlEventTouchUpInside];
    
    _selectPuzzleSizeButton = [UIButton new];
    self.selectPuzzleSizeButton.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:24.f];
    [self.selectPuzzleSizeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.selectPuzzleSizeButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [self.selectPuzzleSizeButton setBackgroundColor:[self colorWithHexString:@"71C7F0"]];
    self.selectPuzzleSizeButton.layer.cornerRadius = 5.0f;
    [self.selectPuzzleSizeButton setTitle:@"Select Puzzle Size" forState:UIControlStateNormal];
    [self.selectPuzzleSizeButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:.4] forState:UIControlStateHighlighted];
    
    
    self.backButton = [UIButton new];
    [self.backButton setImage:[UIImage imageNamed:@"icon-back"] forState:UIControlStateNormal];
}

# pragma mark - navigation

- (void)selectPuzzleSizeButtonDidPress:(id)sender {
    //Create select action
    RMAction *selectAction;
    if (self.opponent == nil) {
        selectAction = [RMAction actionWithTitle:@"Choose Opponent" style:RMActionStyleDone andHandler:^(RMActionController *controller) {
            controller.disableBlurEffectsForBackgroundView = YES;
            controller.disableBlurEffects = YES;
            controller.disableBlurEffectsForContentView = YES;

            UIPickerView *picker = ((RMPickerViewController *)controller).picker;
            
            NSString *puzzleSizeText;
            for(NSInteger i=0 ; i<[picker numberOfComponents] ; i++) {
                self.puzzleSize = [self.puzzleSizes objectAtIndex:[picker selectedRowInComponent:i]];
               // NSLog(@"index of puzzle size picker %ld", (long)[picker selectedRowInComponent:i]);
                puzzleSizeText = [NSString stringWithFormat:@"%@%@", @"          ", self.puzzleSize];
            }
            
            NSLog(@"puzzle size selected: %@", self.puzzleSize);
            [self performSegueWithIdentifier:@"chooseOpponent" sender:self];
        
            self.selectPuzzleSizeButton.titleLabel.text = puzzleSizeText;
        }];
    }
    
    else if (self.opponent != nil) {
        selectAction = [RMAction actionWithTitle:@"Start Game" style:RMActionStyleDone andHandler:^(RMActionController *controller) {
            controller.disableBlurEffectsForBackgroundView = YES;
            controller.disableBlurEffects = YES;
            controller.disableBlurEffectsForContentView = YES;
            
            UIPickerView *picker = ((RMPickerViewController *)controller).picker;
            
            NSString *puzzleSizeText;
            for(NSInteger i=0 ; i<[picker numberOfComponents] ; i++) {
                self.puzzleSize = [self.puzzleSizes objectAtIndex:[picker selectedRowInComponent:i]];
                // NSLog(@"index of puzzle size picker %ld", (long)[picker selectedRowInComponent:i]);
                puzzleSizeText = [NSString stringWithFormat:@"%@%@", @"          ", self.puzzleSize];
            }
            
            NSLog(@"puzzle size selected: %@", self.puzzleSize);
            [self sendGame:self]; // start game
            self.selectPuzzleSizeButton.titleLabel.text = puzzleSizeText;
        }];
    }
    
    
    RMAction *cancelAction = [RMAction actionWithTitle:@"Cancel" style:RMActionStyleCancel andHandler:^(RMActionController *controller) {
        NSLog(@"Row selection was canceled");
    }];

    //Create picker view controller
    RMPickerViewController *pickerController = [RMPickerViewController actionControllerWithStyle:RMActionControllerStyleWhite selectAction:selectAction andCancelAction:cancelAction];
    pickerController.picker.delegate = self;
    pickerController.picker.dataSource = self;
    
    //Now just present the picker controller using the standard iOS presentation method
    [self presentViewController:pickerController animated:YES completion:nil];
}

- (IBAction)backButtonDidPress:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

# pragma mark - upload game methods logic

- (IBAction)sendGame:(id)sender { // after creating game, upload it
    // initiate timer for timeout
    self.totalSeconds = [NSNumber numberWithInt:0];
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(incrementTime) userInfo:nil repeats:YES];
    NSData *fileData;
    NSString *fileName;
    NSString *fileType;
    
    if (self.imageView.image != nil) { //  make sure that there is no problem and that image was selected
        if (self.puzzleSize != nil) { // make sure a puzzle size was chosen in memory
            UIImage* tempEditedImage = [self imageWithDrawing];
            fileData = UIImageJPEGRepresentation(tempEditedImage, 0.4); // compress original image
            fileName = @"image.jpg";
            fileType = @"image";
            NSLog(@"image before upload: %@", tempEditedImage);
            // Adds a status below the circle
            [KVNProgress showWithStatus:@"Starting game... Get ready to solve the puzzle as fast as possible."];
            [self setViewModelProperties]; // set view model properties
            self.createdGame = [self.viewModel setGameKeyParameters:fileData fileType:fileType fileName:fileName]; // set all of the key values that the cloud game model requires. this is for new games and games where the receiver has yet to send back.
            
            // save image file and cloud game model
            [self.viewModel saveFile:^(BOOL succeeded, NSError *error) {
                if (error) {
                    [self.timeoutTimer invalidate];
                    [KVNProgress dismiss];
                    [self.navigationController popViewControllerAnimated:YES]; // go back a VC
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred." message:@"Please try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [alertView show];
                }
               
                else {
                    [self.viewModel saveCurrentGame:^(BOOL succeeded, NSError *error) {
                        if (error) {
                            NSLog(@"error");
                        }
                       
                        else {
                            [self.timeoutTimer invalidate];
                            NSLog(@"this was the uploaded game cloud object: %@", self.createdGame);
                            [NSThread sleepForTimeInterval:2];
                            [KVNProgress dismiss];
                            [self performSegueWithIdentifier:@"startGame" sender:self];
                        }
                    }];
                } // dismiss progressview if first error or after last save. invalidate timer if first error or after last save. go back a VC if error.
            }];
        }
        
        else {
            NSLog(@"you didn't choose a size");
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Puzzle Size" message:@"Please select a puzzle size." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        }
    }
    
    else {
        NSLog(@"some problem");
    }
}

# pragma mark - timer methods logic

- (void)incrementTime {
    int value = [self.totalSeconds intValue];
    self.totalSeconds = [NSNumber numberWithInt:value + 1];
    NSLog(@"%@", self.totalSeconds);
    
    // if too much time passed in uploading
    if ([self.totalSeconds intValue] > 30) {
        NSLog(@"timeout error. took longer than 20 seconds");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred." message:@"Please try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        [KVNProgress dismiss];
        [self.timeoutTimer invalidate];
    }
}

- (void)incrementSavePhotoTimer {
    int value = [self.totalSecondsSavePhotoTimer intValue];
    self.totalSecondsSavePhotoTimer = [NSNumber numberWithInt:value + 1];
    
    // after one second
    if ([self.totalSecondsSavePhotoTimer intValue] > 1) {
        [KVNProgress dismiss];
        [self.savePhotoTimer invalidate];
    }
    
}

#pragma mark - UIPickerView methods logic


- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self.puzzleSizes objectAtIndex:row];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.puzzleSizes count];
}

#pragma mark - JotViewController methods logic

// returns the drawed on image
- (UIImage *)imageWithDrawing
{
    UIImage *myImage = self.gameImage;
    return [self.jotViewController drawOnImage:myImage];
}


// actions
- (void)clearButtonAction
{
    [self.jotViewController clearDrawing];
}

- (void)saveButtonAction
{
    self.totalSecondsSavePhotoTimer = [NSNumber numberWithInt:0];
    self.savePhotoTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(incrementSavePhotoTimer) userInfo:nil repeats:YES];
    [KVNProgress showWithStatus:@"Saving photo to camera roll..."];
    UIImage *drawnImage = [self imageWithDrawing];
    
    ALAssetsLibrary *library = [ALAssetsLibrary new];
    [library writeImageToSavedPhotosAlbum:[drawnImage CGImage]
                              orientation:(ALAssetOrientation)[drawnImage imageOrientation]
                          completionBlock:^(NSURL *assetURL, NSError *error){
                              if (error) {
                                  NSLog(@"Error saving photo: %@", error.localizedDescription);
                                  [KVNProgress dismiss];
                              } else {
                                  NSLog(@"Saved photo to saved photos album.");
                              }
                          }];
}

- (void)toggleDrawingButtonAction
{
    self.jotViewController.state = JotViewStateDrawing;
    [self.toggledDrawingButton setImage:[UIImage imageNamed:kDrawModeActiveImageName] forState:UIControlStateNormal]; // change image to active
    self.untoggledDrawingButton.hidden = YES; // hide untoggled button
    self.toggledDrawingButton.hidden = NO ; // unhide toggled button
    self.clearButton.hidden = NO; // unhide clear button
    self.untoggledTextButton.hidden = YES; // hide text button
    self.toggledTextButton.hidden = YES; // hide text button
    self.selectPuzzleSizeButton.hidden = YES;
    self.saveButton.hidden = YES;
    self.backButton.hidden = YES;
}

- (void)untoggleDrawingButtonAction
{
    self.jotViewController.state = nil; // no draw state anymore
    [self.untoggledDrawingButton setImage:[UIImage imageNamed:kDrawModeInactiveImageName] forState:UIControlStateNormal]; // change image to active
    self.toggledDrawingButton.hidden = YES; // hide toggled
    self.untoggledDrawingButton.hidden = NO; // unhide untoggled
    self.clearButton.hidden = YES; // hide clear button
    self.untoggledTextButton.hidden = NO; // unhide text button
    self.selectPuzzleSizeButton.hidden = NO;
    self.saveButton.hidden = NO;
    self.backButton.hidden = NO;
}


- (void)toggleTextButtonAction
{
    self.jotViewController.state = JotViewStateEditingText;
    self.untoggledTextButton.hidden = YES;
    self.toggledTextButton.hidden = NO;
}

- (void)untoggleTextButtonAction
{
    self.jotViewController.state = nil;
    self.untoggledTextButton.hidden = NO;
    self.toggledTextButton.hidden = YES;
}


// JotViewControllerDelegate



- (void)jotViewController:(JotViewController *)jotViewController isEditingText:(BOOL)isEditing
{
    if (isEditing == TRUE) {
        self.untoggledTextButton.hidden = YES;
        self.toggledTextButton.hidden = NO;
    }
}

# pragma mark - pass data methods

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"startGame"]) {
        GameViewController *gameViewController = (GameViewController *)segue.destinationViewController;
        NSLog(@"image!!! %@", [self imageWithDrawing]);
        gameViewController.puzzleImage = [self imageWithDrawing]; // get the drawed on image
        gameViewController.opponent = self.opponent;
        NSLog(@"the opponent %@", gameViewController.opponent);
        gameViewController.createdGame = self.createdGame;

    }
    
    if ([segue.identifier isEqualToString:@"chooseOpponent"]) {
         UserSelectionViewController *userSelectVC = (UserSelectionViewController *)segue.destinationViewController;
         userSelectVC.puzzleImage = [self imageWithDrawing]; // get the drawed on image
         userSelectVC.opponent = self.opponent;
         userSelectVC.createdGame = self.createdGame;
         userSelectVC.puzzleSize = self.puzzleSize;
    }
}


# pragma mark - set view model method

- (void)setViewModelProperties {
    _viewModel.opponent = self.opponent;
    _viewModel.createdGame = self.createdGame;
    _viewModel.puzzleSize = self.puzzleSize;
}

# pragma mark - image methods

-(UIImage*)prepareImageForGame:(UIImage*)image {
    if (image.size.height > image.size.width) { // portrait
        image = [self imageWithImage:image scaledToFillSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 60)]; // portrait; resizing photo so it fits the entire device screen
    }
    
    else if (image.size.width > image.size.height) { // landscape
        image = [self imageWithImage:image scaledToFillSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 60)];
    }
    
    else if (image.size.width == image.size.height) { // square
        image = [self imageWithImage:image scaledToFillSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 60)];
    }
    
    NSLog(@"image after resizing: %@", image);
    return image;
}

-(UIImage*)prepareImageForPreview:(UIImage*)image {
    if (image.size.height > image.size.width) { // portrait
        image = [self imageWithImage:image scaledToFillSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height)]; // portrait; resizing photo so it fits the entire device screen
    }
    
    else if (image.size.width > image.size.height) { // landscape
        image = [self imageWithImage:image scaledToFillSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height)];
    }
    
    else if (image.size.width == image.size.height) { // square
        image = [self imageWithImage:image scaledToFillSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height )];
    }
    
    NSLog(@"image after resizing: %@", image);
    return image;
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
