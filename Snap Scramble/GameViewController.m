//
//  GameViewController.m
//  Snap Scramble
//
//  Created by Tim Gorer on 7/20/15.
//  Copyright (c) 2015 Tim Gorer. All rights reserved.
//

#import "GameViewController.h"
#import "GameOverViewController.h"
#import "ChallengeViewController.h"
#import "CreatePuzzleViewController.h"
#import "PauseViewController.h"
#import "PuzzleView.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <KVNProgress/KVNProgress.h>
#import "CameraViewController.h"



@interface GameViewController () 

@property (nonatomic) NSInteger pieceNum;
@property (strong,nonatomic) NSMutableArray* targets;
@property (strong,nonatomic) NSMutableArray* pieces;
@property (nonatomic) PuzzleView *pView;


@end

@implementation GameViewController

NSString * const kSaveImageName2 = @"download-button";


- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _viewModel = [[GameViewModel alloc] initWithOpponent:self.opponent andGame:self.createdGame];
    }
    
    return self;
}

# pragma mark - view methods

- (void)viewDidLoad {
    [super viewDidLoad];
    self.statsButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.statsButton.hidden = YES;
    self.statsButton.userInteractionEnabled = NO;
    [self.view addSubview:self.statsButton];
    self.mainMenuButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.mainMenuButton.hidden = YES;
    self.mainMenuButton.userInteractionEnabled = NO;
    [self.view addSubview:self.mainMenuButton];
    self.replyButton.hidden = YES;
    self.replyButton.userInteractionEnabled = NO;
    self.replyLaterButton.hidden = YES;
    self.replyLaterButton.userInteractionEnabled = NO;
    [self.replyButton addTarget:self action:@selector(replyButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.replyLaterButton addTarget:self action:@selector(replyLaterButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.deleteButton addTarget:self action:@selector(deleteButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.statsButton addTarget:self action:@selector(statsButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
   [self.mainMenuButton addTarget:self action:@selector(mainMenuButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
    
    _saveButton = [UIButton new];
    self.saveButton.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:24.f];
    [self.saveButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.saveButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [self.saveButton setImage:[UIImage imageNamed:kSaveImageName2] forState:UIControlStateNormal];
    [self.saveButton addTarget:self
                        action:@selector(saveButtonAction)
              forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.saveButton];
    [self.saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.and.width.equalTo(@44);
        make.right.equalTo(self.view).offset(-14.f);
        make.top.equalTo(self.view).offset(38.f);
    }];
    self.saveButton.hidden = YES;
    
    // GAME & PUZZLE INITIALIZATION code
    self.puzzle = [[PuzzleObject alloc] initWithImage:self.puzzleImage andPuzzleSize:[self.createdGame objectForKey:@"puzzleSize"]];
    self.game = [[GameObject alloc] initWithPuzzle:self.puzzle opponent:self.opponent andPFObject:self.createdGame]; // this line of code creates the game object
    self.pView = [[PuzzleView alloc] initWithGameObject:self.game andFrame:CGRectMake( 0, 0, self.view.frame.size.width, self.view.frame.size.height)]; // puzzle view variable
    NSLog(@"stop before here?");
    [self.view addSubview:self.pView]; // add the puzzle view to the main view
    
    
    // Set the delegate
    self.pView.delegate = self; // set the delegate of the puzzle view to be this view controller so that the pause button segue works
    self.game.gameDelegate = self.pView; // this delegate is so that the game object can constantly update the puzzle view's timer label
    self.game.gameUIDelegate = self; // this delegate is so that the game object can update the UI
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
    // Do any additional setup after loading the view, typically from a nib.
    [self.navigationController.navigationBar setHidden:true];
    

}


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return NO;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

// **** UI update methods **** //

- (void)hideShowStatsButtonUI {
    // update the UI
    NSLog(@"executing here to hide the stats button UI");
    self.statsButton.hidden = YES;
    self.statsButton.userInteractionEnabled = NO;
    self.saveButton.hidden = YES;
    self.saveButton.userInteractionEnabled = NO;
}

- (void)hideReplyButtonUI {
    NSLog(@"executing here to hide the reply button UI");
    self.replyButton.hidden = YES;
    self.replyButton.userInteractionEnabled = NO;
    self.replyLaterButton.hidden = YES;
    self.replyLaterButton.userInteractionEnabled = NO;
    self.deleteButton.hidden = YES;
    self.deleteButton.userInteractionEnabled = NO;
}

- (void)hideMainMenuUI {
    NSLog(@"executing here to hide the main menu button UI");
    self.mainMenuButton.hidden = YES;
    self.mainMenuButton.userInteractionEnabled = NO;
    self.saveButton.hidden = YES;
    self.saveButton.userInteractionEnabled = NO;
}

// executes if current user is the receiver (we want the receiver to send back a puzzle). This code is executed when the user plays a game someone else sent him
- (void)updateToReplyButtonUI {
    // update the UI
    [self hideShowStatsButtonUI];
    [self hideMainMenuUI];
    NSLog(@"executing here to show the reply / reply later button UI");
    self.replyButton.hidden = NO;
    self.replyLaterButton.hidden = NO;
    self.replyLaterButton.userInteractionEnabled = YES;
    self.replyButton.userInteractionEnabled = YES;
    self.deleteButton.hidden = NO;
    self.deleteButton.userInteractionEnabled = YES;
    [self.view bringSubviewToFront:self.replyButton];
    [self.view bringSubviewToFront:self.replyLaterButton];
    [self.view bringSubviewToFront:self.deleteButton];
    self.pView.pauseButton.hidden = YES;
}

// executes if current user is the sender. This code is executed when the user starts sending his own game to someone else.
- (void)updateToMainMenuButtonUI {
    [self hideShowStatsButtonUI];
    [self hideReplyButtonUI];
    NSLog(@"executing here to show the main menu button UI");
    self.mainMenuButton.hidden = NO;
    self.mainMenuButton.userInteractionEnabled = YES;
    self.mainMenuButton.titleLabel.font = [UIFont fontWithName:@"Avenir-Next-Medium" size:17];
    self.mainMenuButton.layer.cornerRadius = 5.0;
    
    // set the button size
    CGRect mainMenuButtonFrame = self.mainMenuButton.frame;
    mainMenuButtonFrame.size = CGSizeMake(295.0, 40.0);
    self.mainMenuButton.frame = mainMenuButtonFrame;
    
    [self.mainMenuButton setCenter:CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height - 60)];
    [self.mainMenuButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.mainMenuButton setTitle:@"Main Menu" forState:UIControlStateNormal];
    self.mainMenuButton.backgroundColor = [self colorWithHexString:@"71C7F0"]; // blue
    [self.view bringSubviewToFront:self.mainMenuButton];
    self.pView.pauseButton.hidden = YES;
}

- (void)updateToShowStatsButtonUI {
    // update the UI
    NSLog(@"executing here to show the stats button UI");
    self.statsButton.hidden = NO;
    self.statsButton.userInteractionEnabled = YES;
    self.statsButton.titleLabel.font = [UIFont fontWithName:@"Avenir-Next-Medium" size:17];
    self.statsButton.layer.cornerRadius = 5.0;
    
    // set the button size
    CGRect statsButtonFrame = self.statsButton.frame;
    statsButtonFrame.size = CGSizeMake(295.0, 40.0);
    self.statsButton.frame = statsButtonFrame;
    
    [self.statsButton setCenter:CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height - 60)];
    [self.statsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.statsButton setTitle:@"Next" forState:UIControlStateNormal];
    self.statsButton.backgroundColor = [self colorWithHexString:@"71C7F0"]; // blue
    [self.view bringSubviewToFront:self.statsButton];
    self.saveButton.hidden = NO;
    [self.view bringSubviewToFront:self.saveButton];
    self.pView.pauseButton.hidden = YES;
}

#pragma mark - navigation

- (IBAction)statsButtonDidPress:(id)sender {
    // in the GameOverVC, show stats menu and then change turns
    [self performSegueWithIdentifier:@"showStats" sender:self];
}

- (IBAction)replyLaterButtonDidPress:(id)sender {
    for (UIViewController* viewController in self.navigationController.viewControllers) {
        if ([viewController isKindOfClass:[SwipeNavigationController class]] ) {
            SwipeNavigationController *VC = (SwipeNavigationController*)viewController;
            [self.navigationController popToViewController:VC animated:NO];
            CameraViewController* centerVC = (CameraViewController*)VC.centerViewController;
            [centerVC showLeftVC];
        }
    }
}

- (IBAction)replyButtonDidPress:(id)sender {
    // delegate allows us to transfer user's data back to StartPuzzleVC for creating puzzle game
    [self.delegate receiveReplyGameData2:self.createdGame andOpponent:self.opponent andRound:self.roundObject];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)deleteButtonDidPress:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Are you sure you want to end the game?" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction: [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.viewModel deleteGame:self.createdGame completion:^(BOOL succeeded, NSError *error) {
            if (error) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred." message:@"Please try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alertView show];
            }
            
            else {
                NSLog(@"game deleted successfully.");
                [self openChallengeVC]; // go to main menu
            }
        }];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        // cancelled
    }]];
    
    alert.popoverPresentationController.sourceView = self.view;
    
    [self presentViewController:alert animated:YES
                     completion:nil];
}

// when the main menu button is pressed, send push at that point.
- (IBAction)mainMenuButtonDidPress:(id)sender {
    [self openChallengeVC];
}

- (void)openChallengeVC {
    for (UIViewController* viewController in self.navigationController.viewControllers) {
        if ([viewController isKindOfClass:[SwipeNavigationController class]] ) {
            SwipeNavigationController *VC = (SwipeNavigationController*)viewController;
            [self.navigationController popToViewController:VC animated:NO];
            CameraViewController* centerVC = (CameraViewController*)VC.centerViewController;
            [centerVC showLeftVC];
        }
    }
}

# pragma mark - game methods logic

// pause the timer and perform the segue - this method is called by this VC's delegate in PuzzleView.m
- (void)pause {
    [self.game pause];
    NSLog(@"game is paused");
    [self performSegueWithIdentifier:@"pauseMenu" sender:self];
}

- (void)saveButtonAction
{
    self.totalSecondsSavePhotoTimer = [NSNumber numberWithInt:0];
    self.savePhotoTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(incrementSavePhotoTimer) userInfo:nil repeats:YES];
    [KVNProgress showWithStatus:@"Saving photo to camera roll..."];
    
    ALAssetsLibrary *library = [ALAssetsLibrary new];
    [library writeImageToSavedPhotosAlbum:[self.puzzleImage CGImage]
                              orientation:(ALAssetOrientation)[self.puzzleImage imageOrientation]
                          completionBlock:^(NSURL *assetURL, NSError *error){
                              if (error) {
                                  NSLog(@"Error saving photo: %@", error.localizedDescription);
                                  [KVNProgress dismiss];
                              } else {
                                  NSLog(@"Saved photo to saved photos album.");
                              }
                          }];
}

- (void)deallocGameProperties {
    self.puzzle = nil;
    self.game = nil;
    self.pView = nil;
    self.puzzleImage = nil;
}

# pragma mark - pass data methods

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showStats"]) {
         GameOverViewController *gameOverViewController = (GameOverViewController *)segue.destinationViewController;
        gameOverViewController.createdGame = self.createdGame;
        gameOverViewController.currentUserTotalSeconds = self.game.totalSeconds; // current user's total seconds to solve puzzle
        gameOverViewController.opponent = self.opponent;
        gameOverViewController.puzzle = self.puzzle;
        gameOverViewController.game = self.game;
    }
    
    if ([segue.identifier isEqualToString:@"pauseMenu"]) {
        PauseViewController *pauseViewController = (PauseViewController *)segue.destinationViewController;
        pauseViewController.createdGame = self.createdGame;
        pauseViewController.opponent = self.opponent;
        pauseViewController.game = self.game;
    }
}

# pragma mark - timer methods

- (void)incrementSavePhotoTimer {
    int value = [self.totalSecondsSavePhotoTimer intValue];
    self.totalSecondsSavePhotoTimer = [NSNumber numberWithInt:value + 1];
    
    // after one second
    if ([self.totalSecondsSavePhotoTimer intValue] > 1) {
        [KVNProgress dismiss];
        [self.savePhotoTimer invalidate];
    }
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
