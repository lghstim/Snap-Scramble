//
//  UserSelectionViewController.m
//  Snap Scramble
//
//  Created by Tim Gorer on 3/5/16.
//  Copyright © 2016 Tim Gorer. All rights reserved.
//

#import "UserSelectionViewController.h"
#import "Reachability.h"
#import "ChallengeViewController.h"
#import "Snap_Scramble-Swift.h"
#import "CreatePuzzleViewController.h"
#import "FriendsTableViewController.h"
#import "PreviewPuzzleViewModel.h"

@interface UserSelectionViewController ()

@property(nonatomic, strong) PreviewPuzzleViewModel *viewModel;

@end

@implementation UserSelectionViewController

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _viewModel = [[PreviewPuzzleViewModel alloc] init];
    }
    return self;
}

# pragma mark - view methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.friendsListButton addTarget:self action:@selector(openFriendsList:) forControlEvents:UIControlEventTouchUpInside];
   [self.randomUserButton addTarget:self action:@selector(randomOpponentButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelButton addTarget:self action:@selector(cancelButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
    self.cancelButton.adjustsImageWhenHighlighted = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.navigationController.navigationBar setHidden:true];
    self.randomUserButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.randomUserButton.titleLabel.minimumScaleFactor = 0.5;
    self.friendsListButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.friendsListButton.titleLabel.minimumScaleFactor = 0.5;
    self.opponentSelectionLabel.adjustsFontSizeToFitWidth = YES;
    self.opponentSelectionLabel.minimumScaleFactor = 0.5;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setHidden:false];
}

- (void)updatetoStartGameUI {
    _startGameButton = [UIButton new];
    self.startGameButton.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:24.f];
    [self.startGameButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.startGameButton setShowsTouchWhenHighlighted:YES];
    [self.startGameButton setBackgroundColor:[self colorWithHexString:@"71C7F0"]];
    self.startGameButton.layer.cornerRadius = 5.0f;
    [self.startGameButton setTitle:@"Start Game" forState:UIControlStateNormal];
    [self.view addSubview:self.startGameButton];
    [self.startGameButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@40);
        make.width.equalTo(@250);
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view);
    }];
    [self.startGameButton addTarget:self action:@selector(sendGame:) forControlEvents:UIControlEventTouchUpInside];
    [self.view bringSubviewToFront:self.startGameButton];
    self.friendsListButton.hidden = YES;
    self.randomUserButton.hidden = YES;
    self.startGameButton.hidden = NO;
}

# pragma mark - navigation

- (IBAction)openFriendsList:(id)sender {
    [self performSegueWithIdentifier:@"selectFriend" sender:self];
}

- (IBAction)randomOpponentButtonDidPress:(id)sender {
    [self findRandomOpponent];
}

- (IBAction)cancelButtonDidPress:(id)sender {
    self.scoreView.animation = @"fall";
    [self.scoreView animate];
    [self.navigationController popViewControllerAnimated:YES];
}

# pragma mark - game logic

- (void)findRandomOpponent {
    self.totalSeconds = [NSNumber numberWithInt:0];
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(incrementTime) userInfo:nil repeats:YES];
    
    // cloud code call to get a random user from a list of 500 users
    [KVNProgress showWithStatus:@"Searching for random opponent..."];
    [PFCloud callFunctionInBackground:@"getRandomOpponent" withParameters:@{} block:^(id opponent, NSError *error) {
        if (!error) {
            [NSThread sleepForTimeInterval:2];
            [KVNProgress dismiss];
            NSLog(@"No error, the random opponent that was found was: %@", opponent);
            self.opponent = (PFUser *)opponent[0]; // get the first opponent in the list
            [self.timeoutTimer invalidate];
            [self updatetoStartGameUI];
        }
    }];
}

- (IBAction)sendGame:(id)sender { // after creating game, upload it
    // initiate timer for timeout
    self.totalSeconds = [NSNumber numberWithInt:0];
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(incrementTime) userInfo:nil repeats:YES];
    NSData *fileData;
    NSString *fileName;
    NSString *fileType;
    
    if (self.puzzleImage != nil) { //  make sure that there is no problem and that image was selected
        if (self.puzzleSize != nil) { // make sure a puzzle size was chosen in memory
            UIImage* tempEditedImage = self.puzzleImage;
            fileData = UIImageJPEGRepresentation(tempEditedImage, 0.4); // compress original image
            fileName = @"image.jpg";
            fileType = @"image";
            self.startGameButton.userInteractionEnabled = NO;
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
                            self.startGameButton.userInteractionEnabled = YES;
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

# pragma mark - timer method logic

- (void)incrementTime {
    int value = [self.totalSeconds intValue];
    self.totalSeconds = [NSNumber numberWithInt:value + 1];
    NSLog(@"%@", self.totalSeconds);
    
    // if too much time passed
    if ([self.totalSeconds intValue] > 15) {
        [KVNProgress dismiss];
        NSLog(@"timeout error. took longer than 15 seconds");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Woops!" message:@"Unfortunately an error occurred in finding an opponent. Please try again later." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        [KVNProgress dismiss];
        [self.timeoutTimer invalidate];
    }
}


#pragma mark - pass data methods

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
 
    if ([segue.identifier isEqualToString:@"selectFriend"]) {
        FriendsTableViewController *friendsTableViewController = (FriendsTableViewController *)segue.destinationViewController;
        friendsTableViewController.delegate = self;
    }
    
    // only called when the delegate receives the random user. Then we can create the game.
    else if ([segue.identifier isEqualToString:@"createPuzzle"]) {
        CreatePuzzleViewController  *createPuzzleViewController = (CreatePuzzleViewController *)segue.destinationViewController;
        createPuzzleViewController.opponent = self.opponent; // random user that was selected
    }
    
    // only called when the delegate receives the random user. Then we can create the game.
    else if ([segue.identifier isEqualToString:@"startGame"]) {
        GameViewController  *gameVC = (GameViewController *)segue.destinationViewController;
        gameVC.opponent = self.opponent; // random user that was selected
        gameVC.puzzleImage = self.puzzleImage; // get the drawed on image
        gameVC.createdGame = self.createdGame;
    }
}

#pragma mark - view model setter method

- (void)setViewModelProperties {
    _viewModel.opponent = self.opponent;
    _viewModel.createdGame = self.createdGame;
    _viewModel.puzzleSize = self.puzzleSize;
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

#pragma mark - delegate methods

- (void)receiveFriendUserData:(PFUser *)opponent {
    self.opponent = opponent;
    self.opponentSelectionLabel.text = [NSString stringWithFormat:@"Opponent: %@", self.opponent.username];
    [self updatetoStartGameUI];
    NSLog(@"delegate success. (friend) opponent selected: %@", self.opponent);
}


@end
