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
#import "DKEditorView.h"

@interface PreviewPuzzleViewController ()

@property(nonatomic, strong) PreviewPuzzleViewModel *viewModel;

@end

@implementation PreviewPuzzleViewController

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _viewModel = [[PreviewPuzzleViewModel alloc] init];
        
        // editing photo functionality... not working
        /* DKEditorView *dkev = (DKEditorView *)self.view;
        UIGraphicsBeginImageContext(dkev.frame.size);
        [dkev.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *temp = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext(); */
    }
    
    return self;
}

#pragma mark - set view model properties

- (void)setViewModelProperties {
    _viewModel.opponent = self.opponent;
    _viewModel.createdGame = self.createdGame;
    _viewModel.puzzleSize = self.puzzleSize;
}

#pragma mark - view controller methods

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
    self.sendButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.sendButton.titleLabel.minimumScaleFactor = 0.5;

    self.currentUser = [PFUser currentUser];
    
    if (self.previewImage) { // if the image was just created by the player (sender) and is saved in memory, display it
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenRect.size.width, screenRect.size.height)];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.backgroundColor = [UIColor clearColor];
        self.imageView.image = self.previewImage;
        [self.view addSubview:self.imageView];
        [self.view bringSubviewToFront:self.sendButton];
        [self.view bringSubviewToFront:self.backButton];
        [self.view bringSubviewToFront:self.selectPuzzleSizeButton];
        [self.sendButton addTarget:self action:@selector(sendGame:) forControlEvents:UIControlEventTouchUpInside];
        [self.backButton addTarget:self action:@selector(backButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
        [self.selectPuzzleSizeButton addTarget:self action:@selector(selectPuzzleSizeButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
        self.selectPuzzleSizeButton.adjustsImageWhenHighlighted = YES;
        self.sendButton.adjustsImageWhenHighlighted = YES;
        self.backButton.adjustsImageWhenHighlighted = YES;
    }
    
    else {
        NSLog(@"Some problem.");
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

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (IBAction)selectPuzzleSizeButtonDidPress:(id)sender {
    //Create select action
    RMAction *selectAction = [RMAction actionWithTitle:@"Start Game" style:RMActionStyleDone andHandler:^(RMActionController *controller) {
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
    
    
    RMAction *cancelAction = [RMAction actionWithTitle:@"Go Back" style:RMActionStyleCancel andHandler:^(RMActionController *controller) {
        [self.navigationController popViewControllerAnimated:YES];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark - upload game methods

- (IBAction)sendGame:(id)sender { // after creating game, upload it
    // initiate timer for timeout
    self.totalSeconds = [NSNumber numberWithInt:0];
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(incrementTime) userInfo:nil repeats:YES];
    NSData *fileData;
    NSString *fileName;
    NSString *fileType;
    
    if (self.originalImage != nil) { // just make sure that there is no problem and that images were selected
        if (self.puzzleSize != nil) { // make sure a puzzle size was chosen in memory
            UIImage* tempOriginalImage = self.originalImage;
            fileData = UIImageJPEGRepresentation(tempOriginalImage, 0.4); // compress original image
            fileName = @"image.jpg";
            fileType = @"image";
            self.sendButton.userInteractionEnabled = NO;
            NSLog(@"image before upload: %@", self.originalImage);
            // Adds a status below the circle
            [KVNProgress showWithStatus:@"Starting game... Get ready to solve the puzzle as fast as possible."];
            [self setViewModelProperties]; // set view model properties
            self.createdGame = [self.viewModel setGameKeyParameters:fileData fileType:fileType fileName:fileName]; // set all of the key values that the cloud game model requires. this is for new games and games where the receiver has yet to send back.
            
            // save image file and cloud game model
            [self.viewModel saveFile:^(BOOL succeeded, NSError *error) {
                if (error) {
                    [KVNProgress dismiss];
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred." message:@"Please try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                    [alertView show];
                }
               
                else {
                    [self.viewModel saveCurrentGame:^(BOOL succeeded, NSError *error) {
                        if (error) {
                            [KVNProgress dismiss];
                            [self.timeoutTimer invalidate];
                        }
                       
                        else {
                            [self.timeoutTimer invalidate];
                            NSLog(@"this was the uploaded game cloud object: %@", self.createdGame);
                            self.sendButton.userInteractionEnabled = YES;
                            [NSThread sleepForTimeInterval:2];
                            [KVNProgress dismiss];
                            [self performSegueWithIdentifier:@"createGame" sender:self];
                        }
                    }];
                }
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


- (void)incrementTime {
    int value = [self.totalSeconds intValue];
    self.totalSeconds = [NSNumber numberWithInt:value + 1];
    NSLog(@"%@", self.totalSeconds);
    
    // if too much time passed in uploading
    if ([self.totalSeconds intValue] > 30) {
        [KVNProgress dismiss];
        NSLog(@"timeout error. took longer than 20 seconds");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred." message:@"Please try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alertView show];
        [self.timeoutTimer invalidate];
        self.sendButton.userInteractionEnabled = YES;
    }
    
}


// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"createGame"]) {
        GameViewController *gameViewController = (GameViewController *)segue.destinationViewController;
        gameViewController.puzzleImage = self.previewImage;
        gameViewController.opponent = self.opponent;
        NSLog(@"the opponent %@", gameViewController.opponent);
        gameViewController.createdGame = self.createdGame;
    }
}

#pragma mark - UIPickerView code


- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self.puzzleSizes objectAtIndex:row];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.puzzleSizes count];
}

@end
