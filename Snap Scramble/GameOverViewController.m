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
}


# pragma mark - view controller methods

- (void)updateStatsView {
    [self setViewModelProperties]; // set view model properties
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
    
    if ([[self.createdGame objectForKey:@"receiverName"] isEqualToString:[PFUser currentUser].username]) { // if current user is the receiver (we want the receiver to send back a puzzle). This code is executed when the user plays a game someone else sent him.
        NSString *opponentName = [self.createdGame objectForKey:@"senderName"];
        self.opponentTotalSeconds = [self.createdGame objectForKey:@"senderTime"];
        
        if (self.opponentTotalSeconds != nil) {
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
            if (self.currentUserTotalSeconds > self.opponentTotalSeconds) {
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
                [PFCloud callFunctionInBackground:@"incrementWins" withParameters:@{@"userId": self.opponent.objectId} block:^(NSNumber *opponentWins, NSError *error) {
                    if (error) {
                        NSLog(@"error incrementing opponent's wins.");
                    } else {
                        NSLog(@"successfully incremented opponent's wins: %@", opponentWins);
                    }
                }];
            } else if (self.currentUserTotalSeconds == self.opponentTotalSeconds) {
                // don't update losses or wins since the game is a tie.
                self.headerStatsLabel.text = @"Tie game! It is your turn to reply now.";
            } else if (self.currentUserTotalSeconds < self.opponentTotalSeconds) {
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
                [PFCloud callFunctionInBackground:@"incrementLosses" withParameters:@{@"userId": self.opponent.objectId} block:^(NSNumber *opponentLosses, NSError *error) {
                    if (error) {
                        NSLog(@"error incrementing opponent's losses.");
                    } else {
                        NSLog(@"successfully incremented opponent's losses: %@", opponentLosses);
                    }
                }];
                
                self.headerStatsLabel.text = @"You won! It is your turn to reply now.";
            }
        }
        
        else {
            NSLog(@"something went wrong.");
        }
    }
    
    else if ([[self.createdGame objectForKey:@"senderName"] isEqualToString:[PFUser currentUser].username]) { // if current user is the sender. This code is executed when the user starts sending his own game to someone else.
        NSLog(@"wtf");
        [self.viewModel switchTurns];
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

- (IBAction)doneButtonDidPress:(id)sender {
    [self.viewModel updateGame]; // update the game appropriately once current user has played

    //This for loop iterates through all the view controllers in navigation stack.
    for (UIViewController* viewController in self.navigationController.viewControllers) {
        if ([viewController isKindOfClass:[GameViewController class]] ) {
            GameViewController *gameViewController = (GameViewController *)viewController;
            
            // the following if statements figure out which UI to display based on what role the user is in (sender or receiver)
            gameViewController.viewModel.opponent = self.opponent;
            gameViewController.viewModel.createdGame = self.createdGame;
            
            
            if ([[self.createdGame objectForKey:@"receiverName"] isEqualToString:[PFUser currentUser].username]) { // if current user is the receiver (we want the receiver to send back a puzzle). This code is executed when the user plays a game someone else sent him.
                NSLog(@"current user is the receiver, show reply button UI");
                [gameViewController updateToReplyButtonUI];
                
            }
            
            else if ([[self.createdGame objectForKey:@"senderName"] isEqualToString:[PFUser currentUser].username]) { // if current user is the sender. This code is executed when the user starts sending his own game to someone else.
                NSLog(@"current user is the sender, show main menu button UI");
                [gameViewController updateToMainMenuButtonUI];
            }
            
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
