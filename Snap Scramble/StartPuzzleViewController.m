//
//  StartPuzzleViewController.m
//  Snap Scramble
//
//  Created by Tim Gorer on 3/5/16.
//  Copyright © 2016 Tim Gorer. All rights reserved.
//

#import "StartPuzzleViewController.h"
#import "GameViewController.h"
#import "Snap_Scramble-Swift.h"
#import "StartPuzzleViewModel.h"

@interface StartPuzzleViewController ()

@property(nonatomic, strong) StartPuzzleViewModel *viewModel;


@end

@implementation StartPuzzleViewController

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _viewModel = [[StartPuzzleViewModel alloc] init];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.cancelButton addTarget:self action:@selector(cancelButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
    self.cancelButton.adjustsImageWhenHighlighted = YES;
    [self setViewModelProperties];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setHidden:false];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // disable swipe back functionality
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:true];
    NSLog(@"Screen Width: %f    Screen Height: %f", self.view.frame.size.width, self.view.frame.size.height);
    [self.startPuzzleButton addTarget:self action:@selector(startGame:) forControlEvents:UIControlEventTouchUpInside]; // start game is when photo resizing happens
    self.startPuzzleButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.startPuzzleButton.titleLabel.minimumScaleFactor = 0.5;
    self.cancelButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.cancelButton.titleLabel.minimumScaleFactor = 0.5;
 

    if (!self.image) { // if the image is being retrieved from the server by the receiving player
        // Adds a status below the circle
        self.totalSeconds = [NSNumber numberWithInt:0];
        self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(incrementTime) userInfo:nil repeats:YES];
        [KVNProgress showWithStatus:@"Downloading..."];
        self.startPuzzleButton.userInteractionEnabled = false;
        [self.startPuzzleButton setTitle:@"Start Puzzle" forState:UIControlStateNormal];
        [[self.createdGame objectForKey:@"file"] getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error) {
                UIImage *image = [UIImage imageWithData:data];
                self.image = image;
                NSLog(@"downloaded image: %@", self.image);
                self.startPuzzleButton.userInteractionEnabled = true;
                
                // update the stats view and then dismiss progress view
                [self updateStatsView];
            } else { // if error
                [KVNProgress dismiss];
                [self.navigationController popToRootViewControllerAnimated:YES];
                [self.timeoutTimer invalidate];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred." message:@"Please try again later." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alertView show];
            } // dismiss progressview if first error or after last save. invalidate timer if first error or after last save. go back a VC if error.
        }];
    }
}

- (void)setViewModelProperties {
    self.viewModel.roundsRelation = [self.createdGame relationForKey:@"rounds"];
}

- (void)updateStatsView {
    NSLog(@"update states view");
    // get the previous round number so we can get the data from that round object
    [self.createdGame fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        if (error) {
            NSLog(@"error");
        } else {
            self.createdGame = object;
            NSNumber *currentRoundNumber = [self.createdGame objectForKey:@"roundNumber"];
            NSNumber *previousRoundNumber = [[NSNumber alloc] init];
            int currentRounderNumberInt = [currentRoundNumber intValue];
            if (currentRounderNumberInt == 1) { // if it's the first round then there is no previous round
                NSLog(@"round 1");
                int previousRoundNumberInt = 1;
                previousRoundNumber = [NSNumber numberWithInt:previousRoundNumberInt];
            } else {
                int previousRoundNumberInt = [currentRoundNumber intValue] - 1;
                previousRoundNumber = [NSNumber numberWithInt:previousRoundNumberInt];
            }
            
            [self.viewModel getRoundObject:^(PFObject *round, NSError *error) { // get previous round object
                NSLog(@"hello");
                if (error) {
                    NSLog(@"error");
                } else {
                    [self.timeoutTimer invalidate]; // invalidate the timer if success
                    [KVNProgress dismiss]; // dismiss downloading view
                    NSLog(@"pass");
                    // display the data from the previous round object
                    self.previousRoundObject = round;
                    
                
                    NSString *opponentName = @""; // placeholder
                    
                    // figure out who is who
                    if ([[self.previousRoundObject objectForKey:@"receiverName"] isEqualToString:[PFUser currentUser].username]) {
                        opponentName = [self.previousRoundObject objectForKey:@"senderName"]; // opponent was sender last round
                        self.opponentTotalSeconds = [self.previousRoundObject objectForKey:@"senderTime"]; // opponent total seconds
                        self.currentUserTotalSeconds = [self.previousRoundObject objectForKey:@"receiverTime"];
                        
                    } else if ([[self.previousRoundObject objectForKey:@"senderName"] isEqualToString:[PFUser currentUser].username]) {
                        opponentName = [self.previousRoundObject objectForKey:@"receiverName"]; // opponent was receiver last round
                        self.opponentTotalSeconds = [self.previousRoundObject objectForKey:@"receiverTime"]; // opponent total seconds
                        self.currentUserTotalSeconds = [self.previousRoundObject objectForKey:@"senderTime"];
                    }
                    
                    NSLog(@"opponent: %@   opponent time: %@    current user time: %@", opponentName, self.opponentTotalSeconds, self.currentUserTotalSeconds);
                  
                    
                    // format the current user's time
                    int intValueTotalSeconds = [self.currentUserTotalSeconds intValue];
                    NSLog(@"intval: %d", intValueTotalSeconds);
                    int minutes = 0; int seconds = 0;
                    
                    seconds = intValueTotalSeconds % 60;
                    if (intValueTotalSeconds >= 60) {
                        minutes = intValueTotalSeconds / 60;
                    }
                    
                    if (seconds < 10) {
                        self.currentUserTimeLabel.text = [NSString stringWithFormat:@"Your time: %d:0%d", minutes, seconds];
                    }
                    
                    else if (seconds >= 10) {
                        self.currentUserTimeLabel.text = [NSString stringWithFormat:@"Your time: %d:%d", minutes, seconds];
                    }
                    
                    int opponentTotalSecondsInt = [self.opponentTotalSeconds intValue];
                    int currentUserTotalSecondsInt = [self.currentUserTotalSeconds intValue];
                    if (opponentTotalSecondsInt > 0 && currentUserTotalSecondsInt > 0) { // both have played so we can display the data
                        // format the opponent's time
                        int intValueTotalSeconds = [self.opponentTotalSeconds intValue];
                        int minutes = 0; int seconds = 0;
                        
                        seconds = intValueTotalSeconds % 60;
                        if (intValueTotalSeconds >= 60) {
                            minutes = intValueTotalSeconds / 60;
                        }
                        
                        if (seconds < 10) {
                            self.opponentTimeLabel.text = [NSString stringWithFormat:@"%@'s time: %d:0%d", opponentName, minutes, seconds];
                        }
                        
                        else if (seconds >= 10) {
                            self.opponentTimeLabel.text = [NSString stringWithFormat:@"%@'s time: %d:%d", opponentName, minutes, seconds];
                        }
                        
                        // check who won
                        if (self.currentUserTotalSeconds > self.opponentTotalSeconds) { // if current user lost
                            self.headerStatsLabel.text = @"You lost the previous round:";
                        } else if (self.currentUserTotalSeconds == self.opponentTotalSeconds) { // if tie
                            // don't update losses or wins since the game is a tie.
                            self.headerStatsLabel.text = @"You tied the previous round:";
                        } else if (self.currentUserTotalSeconds < self.opponentTotalSeconds) { // if current user won
                            self.headerStatsLabel.text = @"You won the previous round:";
                        }
                    } else if (currentUserTotalSecondsInt == 0 && opponentTotalSecondsInt > 0) { // if only opponent has played last round
                        // format the opponent's time
                        int intValueTotalSeconds = [self.opponentTotalSeconds intValue];
                        int minutes = 0; int seconds = 0;
                        
                        seconds = intValueTotalSeconds % 60;
                        if (intValueTotalSeconds >= 60) {
                            minutes = intValueTotalSeconds / 60;
                        }
                        
                        if (seconds < 10) {
                            self.opponentTimeLabel.text = [NSString stringWithFormat:@"%@'s time: %d:0%d", opponentName, minutes, seconds];
                        }
                        
                        else if (seconds >= 10) {
                            self.opponentTimeLabel.text = [NSString stringWithFormat:@"%@'s time: %d:%d", opponentName, minutes, seconds];
                        }

                        self.headerStatsLabel.text = [NSString stringWithFormat:@"Try to solve the puzzle faster!"];
                        self.currentUserTimeLabel.text = [NSString stringWithFormat:@"You haven't played yet."];

                    }
                }
            } whereRoundNumberIs:previousRoundNumber];
        }
    }];
}

- (void)incrementTime {
    int value = [self.totalSeconds intValue];
    self.totalSeconds = [NSNumber numberWithInt:value + 1];
    NSLog(@"%@", self.totalSeconds);
    
    // if too much time passed in uploading
    if ([self.totalSeconds intValue] > 20) {
        NSLog(@"timeout error. took longer than 20 seconds");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred." message:@"Please try again later." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        [KVNProgress dismiss];
        [self.timeoutTimer invalidate];
    }
}

- (IBAction)startGame:(id)sender {
    self.totalSeconds = [NSNumber numberWithInt:0];
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(pauseForFiveSeconds) userInfo:nil repeats:YES];
    
    // first show preview of the image for a few seconds
    [KVNProgress showWithStatus:[NSString stringWithFormat:@"Here's a preview of %@'s puzzle! Solve it as fast as possible!", self.opponent.username]];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenRect.size.width, screenRect.size.height)];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.backgroundColor = [UIColor clearColor];
    UIImage* previewImage = [self prepareImageForPreview:self.image];
    self.imageView.image = previewImage;
    [self.view addSubview:self.imageView];
    self.gameImage = [self prepareImageForGame:self.image]; // now resize image for the game
}

-(UIImage*)prepareImageForGame:(UIImage*)image {
    if (image.size.height > image.size.width) { // portrait
        image = [self imageWithImage:image scaledToFillSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 30)]; // portrait; resizing photo so it fits the entire device screen
    }
    
    else if (image.size.width > image.size.height) { // landscape
        image = [self imageWithImage:image scaledToFillSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 30)];
    }
    
    else if (image.size.width == image.size.height) { // square
        image = [self imageWithImage:image scaledToFillSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 30)];
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

- (void)pauseForFiveSeconds {
    int value = [self.totalSeconds intValue];
    self.totalSeconds = [NSNumber numberWithInt:value + 1];
    NSLog(@"%@", self.totalSeconds);
    
    if ([self.totalSeconds intValue] > 3) {
        [KVNProgress dismiss];
    }
    
    // if too much time passed in uploading
    if ([self.totalSeconds intValue] > 5) {
        // begin game
        [self performSegueWithIdentifier:@"beginGame" sender:self];
        [self.timeoutTimer invalidate];
    }
    
}

- (IBAction)cancelButtonDidPress:(id)sender {
    self.scoreView.animation = @"fall";
    [self.scoreView animate];
    [self.navigationController popToRootViewControllerAnimated:YES];
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

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"beginGame"]) {
        GameViewController *gameViewController = (GameViewController *)segue.destinationViewController;
        gameViewController.puzzleImage = self.gameImage;
        gameViewController.opponent = self.opponent;
        NSLog(@"opponent %@",gameViewController.opponent);
        gameViewController.createdGame = self.createdGame;
        gameViewController.delegate = self;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - delegate methods

- (void)receiveReplyGameData2:(PFObject *)selectedGame andOpponent:(PFUser *)opponent andRound:(PFObject *)roundObject {
    self.createdGame = selectedGame;
    self.opponent = opponent;
    self.roundObject = roundObject;
    
    // delegate allows us to transfer user's data back to ChallengeViewController for creating puzzle game, which then sends data to CreatePuzzleVC
    [self.delegate receiveReplyGameData:self.createdGame andOpponent:self.opponent andRound:self.roundObject];
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
