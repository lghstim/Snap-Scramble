//
//  GameOverViewController.m
//  Snap Scramble
//
//  Created by Tim Gorer on 7/27/15.
//  Copyright (c) 2015 Tim Gorer. All rights reserved.
//

#import "GameOverViewController.h"
#import "ChallengeViewController.h"
#import "Snap_Scramble-Swift.h"
#import "GameOverViewModel.h"
#import "GameViewController.h"
#import "PuzzleView.h"


@interface GameOverViewController ()



@property(nonatomic, strong) GameOverViewModel *viewModel;

@end

// this view controller displays stats
@implementation GameOverViewController

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _viewModel = [[GameOverViewModel alloc] init];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.doneButton addTarget:self action:@selector(doneButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
    self.doneButton.adjustsImageWhenHighlighted = NO;
    self.currentUserTimeLabel.adjustsFontSizeToFitWidth = YES;
    self.currentUserTimeLabel.contentScaleFactor = 0.5;
    self.opponentTimeLabel.adjustsFontSizeToFitWidth = YES;
    self.opponentTimeLabel.contentScaleFactor = 0.5;
    self.headerStatsLabel.adjustsFontSizeToFitWidth = YES;
    self.headerStatsLabel.minimumScaleFactor = 0.5;
    self.headerStatsLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.headerStatsLabel.numberOfLines = 2;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.navigationController.navigationBar setHidden:true];
    [self updateStatsView]; // update the stats view since the game is over
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setHidden:false];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


# pragma mark - set view model properties

- (void)setViewModelProperties {
    self.viewModel.createdGame = self.createdGame;
    self.viewModel.currentUserTotalSeconds = self.currentUserTotalSeconds;
    self.viewModel.opponent = self.opponent;
    self.viewModel.roundsRelation = [self.createdGame relationForKey:@"rounds"];
    self.viewModel.roundObject = [PFObject objectWithClassName:@"Round"]; // round object
}


# pragma mark - view controller methods

- (void)updateStatsView {
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
    
    [KVNProgress showWithStatus:@"Loading..."];
    [self setViewModelProperties]; // set view model properties
    [self.viewModel updateGame:^(BOOL succeeded, NSError *error) {
        if (error) {
            [KVNProgress dismiss];
             UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred." message:@"Please try playing again later." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
             [alertView show];
         } else {
             [KVNProgress dismiss];
             NSLog(@"game saved successfully. %@", self.createdGame);
             // update the game appropriately once current user has played
             if ([[self.createdGame objectForKey:@"receiverName"] isEqualToString:[PFUser currentUser].username]) { // if current user is the receiver (we want the receiver to send back a puzzle). This code is executed when the user plays a game someone else sent him.
                 NSString *opponentName = [self.createdGame objectForKey:@"senderName"];
                 self.opponentTotalSeconds = [self.createdGame objectForKey:@"senderTime"];
                 
                 int opponentTotalSecondsInt = [self.opponentTotalSeconds intValue];
                 int currentUserTotalSecondsInt = [self.currentUserTotalSeconds intValue];
                 if (opponentTotalSecondsInt > 0) { // make sure opponent played if current user is receiver
                     
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
                     if (currentUserTotalSecondsInt > opponentTotalSecondsInt) { // if current user lost
                         self.headerStatsLabel.text = @"You lost! It is your turn to reply now.";
                         // update the amount of losses the current user has.
                         NSNumber *losses = [[PFUser currentUser] objectForKey:@"losses"];
                         if (losses != nil) {
                             int intLosses = [losses intValue];
                             losses = [NSNumber numberWithInt:intLosses + 1];
                             [[PFUser currentUser] setObject:losses forKey:@"losses"];
                             [self.viewModel saveCurrentUser:^(BOOL succeeded, NSError *error) {
                                 if (error) {
                                     NSLog(@"failed updating losses");
                                 } else {
                                     
                                     NSLog(@"current user losses: %@", losses);
                                 }
                             }];
                         } else {
                             losses = [NSNumber numberWithInt:1];
                             int intLosses = [losses intValue];
                             [[PFUser currentUser] setObject:losses forKey:@"losses"];
                             [self.viewModel saveCurrentUser:^(BOOL succeeded, NSError *error) {
                                 if (error) {
                                     NSLog(@"failed updating losses");
                                 } else {
                                     NSLog(@"current user losses: %d", intLosses);
                                 }
                             }];
                         }
                         
                         // update the amount of wins the opponent has.
                         [self.viewModel incrementWins];
                     } else if (currentUserTotalSecondsInt == opponentTotalSecondsInt) { // if tie
                         // don't update losses or wins since the game is a tie.
                         self.headerStatsLabel.text = @"Tie game! It is your turn to reply now.";
                     } else if (currentUserTotalSecondsInt < opponentTotalSecondsInt) { // if current user won
                         // update the amount of wins the current user has.
                         NSNumber *wins = [[PFUser currentUser] objectForKey:@"wins"];
                         if (wins != nil) {
                             int intWins = [wins intValue];
                             wins = [NSNumber numberWithInt:intWins + 1];
                             [[PFUser currentUser] setObject:wins forKey:@"wins"];
                             [self.viewModel saveCurrentUser:^(BOOL succeeded, NSError *error) {
                                 if (error) {
                                     NSLog(@"failed updating wins");
                                 } else {
                                     NSLog(@"current user wins: %@", wins);
                                 }
                             }];
                         } else {
                             wins = [NSNumber numberWithInt:1];
                             int intWins = [wins intValue];
                             [[PFUser currentUser] setObject:wins forKey:@"wins"];
                             [self.viewModel saveCurrentUser:^(BOOL succeeded, NSError *error) {
                                 if (error) {
                                     NSLog(@"failed updating wins");
                                 } else {
                                     NSLog(@"current user wins: %d", intWins);
                                 }
                             }];
                         }
                         
                         // update the amount of losses the opponent has.
                         [self.viewModel incrementLosses];
                         self.headerStatsLabel.text = @"You won! It is your turn to reply now.";
                     }
                 }
                 
                 else {
                     NSLog(@"something went wrong.");
                 }
             }
             
             else if ([[self.createdGame objectForKey:@"senderName"] isEqualToString:[PFUser currentUser].username]) { // if current user is the sender. This code is executed when the user starts sending his own game to someone else.
                 [self.viewModel switchTurns]; // switch turns
                 [self.viewModel saveCurrentGame:^(BOOL succeeded, NSError *error) {
                     if (error) {
                         UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred." message:@"Please try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                         [alertView show];
                     }
                     
                     else { // sent game
                         NSLog(@"the turn was switched successfully.");
                         NSString *opponentName = [self.createdGame objectForKey:@"receiverName"];
                         self.headerStatsLabel.text = [NSString stringWithFormat:@"It is %@'s turn to play now!", opponentName];
                         self.opponentTimeLabel.text = [NSString stringWithFormat:@"%@ hasn't played yet.", opponentName];
                     }
                 }];
             }
         }
    }]; // dismiss progressview if first error or after last save. 
}

- (IBAction)doneButtonDidPress:(id)sender {
    //This for loop iterates through all the view controllers in navigation stack.
    for (UIViewController* viewController in self.navigationController.viewControllers) {
        if ([viewController isKindOfClass:[GameViewController class]] ) {
            GameViewController *gameViewController = (GameViewController *)viewController;
            
            // the following if statements figure out which UI to display based on what role the user is in (sender or receiver)
            gameViewController.viewModel.opponent = self.opponent;
            gameViewController.viewModel.createdGame = self.createdGame;
            
            
            if ([[self.createdGame objectForKey:@"receiverName"] isEqualToString:[PFUser currentUser].username]) { // if current user is the receiver (we want the receiver to send back a puzzle). This code is executed when the user plays a game someone else sent him.
                NSLog(@"current user is the receiver, show reply button UI");
                gameViewController.roundObject = self.viewModel.roundObject;
                [gameViewController updateToReplyButtonUI];
                
            }
            
            else if ([[self.createdGame objectForKey:@"senderName"] isEqualToString:[PFUser currentUser].username]) { // if current user is the sender. This code is executed when the user starts sending his own game to someone else.
                NSLog(@"current user is the sender, now go back to main menu");
                
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
            
            [gameViewController deallocGameProperties];
            self.statsView.animation = @"fall";
            [self.statsView animate];
            [self.navigationController popToViewController:gameViewController animated:YES];
            break;
        }
    }
}






/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
