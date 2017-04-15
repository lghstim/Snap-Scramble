//  ChallengeViewController.m
//  Snap Scramble
//
//  Created by Tim Gorer on 7/20/15.
//  Copyright (c) 2015 Tim Gorer. All rights reserved.
//

#import "ChallengeViewController.h"
#import "PreviewPuzzleViewController.h"
#import "CreatePuzzleViewController.h"
#import "Reachability.h"
#import "ChallengeViewModel.h"
#import "IAPViewController.h"
#import "SnapScrambleCell.h"
#import "SettingsViewController.h"
#import "CameraViewController.h"
#import "AppDelegate.h"
#import "Snap_Scramble-Swift.h"
#import <SwipeNavigationController/SwipeNavigationController.h>

@import Firebase;
@import SwipeNavigationController;




@interface ChallengeViewController ()

@property(nonatomic, strong) ChallengeViewModel *viewModel;

@end

@implementation ChallengeViewController

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _viewModel = [[ChallengeViewModel alloc] init];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.clipsToBounds = TRUE;
    self.currentGamesTable.delegate = self;
    self.currentGamesTable.dataSource = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTable:) name:@"reloadTheTable" object:nil]; // reload the table if the user receives a notification?
    [self setNavigationBar];
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(retrieveUserMatches) forControlEvents:UIControlEventValueChanged];
    [self.currentGamesTable addSubview:self.refreshControl];
    [self.headerView addSubview:self.usernameLabel];
    self.currentGamesTable.tableHeaderView = self.headerView;
    self.currentGamesTable.delaysContentTouches = NO;
    [self.currentGamesTable setContentInset:UIEdgeInsetsMake(43, 0, -300, 0)];
    UINib *nib = [UINib nibWithNibName:@"SnapScrambleCell" bundle:nil];
    [[self currentGamesTable] registerNib:nib forCellReuseIdentifier:@"Cell"];

    


    // initialize a view for displaying the empty table screen if a user has no games.
    self.emptyTableScreen = [[UIImageView alloc] init];
    [self.challengeButton addTarget:self action:@selector(playButtonDidPress:) forControlEvents:UIControlEventTouchUpInside]; // starts an entirely new game if pressed. don't be confused
    self.challengeButton.adjustsImageWhenHighlighted = NO;
    [self setUpLongPressCell];
    
    // check for internet connection, send a friendly message.
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    
    if (networkStatus == NotReachable) { // if there's no internet
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Woops!" message:@"Your device appears to not have an internet connection. Unfortunately Snap Scramble requires internet to play." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
    }
}

- (void)setUpLongPressCell {
    // attach long press gesture to collectionView
    UILongPressGestureRecognizer *lpgr
    = [[UILongPressGestureRecognizer alloc]
       initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.delegate = self;
    lpgr.delaysTouchesBegan = YES;
    [self.currentGamesTable addGestureRecognizer:lpgr];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        NSLog(@"Current user: %@", currentUser.username);
        [self.currentGamesTable reloadData]; // reload the table view
        [self retrieveUserMatches]; // retrieve all games, both pending and current
        NSString* usernameText = @"Username: ";
        usernameText = [usernameText stringByAppendingString:currentUser.username];
        [self.usernameLabel setText:usernameText];
        [[PFInstallation currentInstallation] setObject:[PFUser currentUser] forKey:@"User"];
        [[PFInstallation currentInstallation] saveInBackground];
    }
    
    else {
        [self performSegueWithIdentifier:@"showSignup" sender:self]; // show sign up screen if user not signed in
    }
    
    [self displayAd]; // display ad, or not if user paid
    [self displayAdsButton]; // display ads button, or not if user paid

}

- (void)setNavigationBar {
    UINavigationBar *navbar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    navbar.backgroundColor = [self colorWithHexString:@"71C7F0"];
    navbar.barTintColor = [self colorWithHexString:@"71C7F0"];
    UINavigationItem* navItem = [[UINavigationItem alloc] initWithTitle:@"Snap Scramble"];
    [navItem.titleView setFrame:CGRectMake(navItem.titleView.frame.origin.x, navItem.titleView.frame.origin.y + 30, navItem.titleView.frame.size.width, navItem.titleView.frame.size.height)];
    [navbar setItems:@[navItem]];
    [self.view addSubview:navbar];
    [self.view bringSubviewToFront:navbar];
}

-(void)viewWillDisappear:(BOOL)animated {
    [self.currentGamesTable reloadData];
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        [self retrieveUserMatches];
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)reloadTable:(NSNotification *)notification {
    [self retrieveUserMatches];
}

// this starts an entirely new game, don't be confused.
- (IBAction)selectUserFromOptions:(id)sender {
    NSLog(@"%u", (self.currentGames.count + self.currentPendingGames.count));
    [self performSegueWithIdentifier:@"selectUserOptionsScreen" sender:self];
}

- (void)displayAd{
    NSNumber *adsRemoved = [[NSUserDefaults standardUserDefaults] objectForKey:@"adsRemoved"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"%id", [adsRemoved boolValue]);
    if ([adsRemoved boolValue] != TRUE) {
        self.bannerView.adUnitID = @"ca-app-pub-9099568248089334/4082940202";
        self.bannerView.rootViewController = self;
        GADRequest *request = [GADRequest request];
        //request.testDevices = @[@"117d8d0d0cfc555fabc2f06fb83770b8"];
        [self.bannerView loadRequest:request];
    } else {
        NSLog(@"ads are removed for this user.");
        self.bannerView.hidden = YES;
    }
}

- (IBAction)playButtonDidPress:(id)sender {
   [self.containerSwipeNavigationController showCenterVCWithSwipeVC:self.containerSwipeNavigationController];
}



- (void)displayAdsButton {
    NSNumber *adsRemoved = [[NSUserDefaults standardUserDefaults] objectForKey:@"adsRemoved"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"%id", [adsRemoved boolValue]);
    if ([adsRemoved boolValue] != TRUE) {
        self.removeAdsButton.hidden = FALSE;
        self.removeAdsButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.removeAdsButton.contentScaleFactor = 0.5;
    } else {
        self.removeAdsButton.hidden = TRUE;
    }
}





#pragma mark - userMatchesTable code

- (void)retrieveUserMatches {
    // retrieve current matches
    [self.viewModel retrieveCurrentMatches:^(NSArray *matches, NSError *error) {
        if (error) {
            NSLog(@"Error %@ %@", error, [error userInfo]);
        }
        
        else {
            if ([self.refreshControl isRefreshing]) {
                [self.refreshControl endRefreshing];
            }
            
            self.currentGames = matches;
            [self.currentGamesTable reloadData];
            
            // then retrieve pending matches
            [self.viewModel retrievePendingMatches:^(NSArray *matches, NSError *error) {
                if (error) {
                    NSLog(@"Error %@ %@", error, [error userInfo]);
                }
                
                else {
                    if ([self.refreshControl isRefreshing]) {
                        [self.refreshControl endRefreshing];
                    }
                    
                    self.currentPendingGames = matches;
                    [self.currentGamesTable reloadData];
                    
                    // save games count to User class
                    NSUInteger gamesCount = (self.currentGames.count + self.currentPendingGames.count);
                    NSNumber *gamesCountNSNumber = [NSNumber numberWithInteger:gamesCount];
                    [[PFUser currentUser] setObject:gamesCountNSNumber forKey:@"gamesCount"];
                    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                        if (!error) {
                            NSLog(@"games count saved: %@", gamesCountNSNumber);
                        } else {
                            NSLog(@"error saving games count");
                        }
                    }];
                }
            }];
        }
    }];
    
    // update the score label each time matches are retrieved
    [self updateScoreLabel];
}

- (void)updateScoreLabel {
    self.scoreLabel.adjustsFontSizeToFitWidth = YES;
    self.scoreLabel.contentScaleFactor = 1.0;
    [self.viewModel getCurrentUser:^(PFObject *currentUser, NSError *error) {
        if (error) {
            NSLog(@"error...");
        } else {
            NSNumber *wins = [currentUser objectForKey:@"wins"];
            NSNumber *losses = [currentUser objectForKey:@"losses"];
            int winsInt = [wins intValue];
            int lossesInt = [losses intValue];
            if (winsInt > 0 && lossesInt > 0) {
                // NSLog(@"Wins: %@ | Losses: %@", wins, losses);
                self.scoreLabel.text = [NSString stringWithFormat:@"Wins: %@ | Losses: %@", wins, losses];
            } else if (winsInt > 0 && lossesInt == 0) {
                // NSLog(@"Wins: %@ | Losses: 0", wins);
                self.scoreLabel.text = [NSString stringWithFormat:@"Wins: %@ | Losses: 0", wins];
            } else if (lossesInt > 0 && winsInt == 0) {
                // NSLog(@"Wins: 0 | Losses: %@", losses);
                self.scoreLabel.text = [NSString stringWithFormat:@"Wins: 0 | Losses: %@", losses];
            } else if (lossesInt == 0 && winsInt == 0) {
                // NSLog(@"Wins: 0 | Losses: 0");
                self.scoreLabel.text = [NSString stringWithFormat:@"Wins: 0 | Losses: 0"];
            }
        }
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self.currentGames count] == 0 && [self.currentPendingGames count] == 0) {
        // set the "no games" background image. change this code later on.
        self.backgroundView.hidden = NO;
        self.currentGamesTable.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.currentGamesTable.scrollEnabled = false; // disable scroll if there're no games
    }
    
    
    if ([self.currentGames count] != 0 || [self.currentPendingGames count] != 0) {
        self.backgroundView.hidden = YES;
        self.currentGamesTable.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.currentGamesTable.scrollEnabled = true;
    }
    
    // Return the number of rows in the section.
    if (section == 0) {
        return [self.currentGames count];
    }
    
    if (section == 1) {
        return [self.currentPendingGames count];
    }
    
    return 0;
}

// a method so that the user can delete games he doesn't want to play anymore
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return YES - we will be able to delet rows
    return NO;
}

// deletion functionality
- (void)deleteGame:(NSIndexPath *)indexPath {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete game" message:@"Are you sure you want to delete this game?" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction: [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (indexPath.section == 0) { // current games section
            PFObject *gameToDelete = [self.currentGames objectAtIndex:indexPath.row];
            NSMutableArray* tempCurrentGames = [NSMutableArray arrayWithArray:self.currentGames];
            
            [self.viewModel deleteGame:gameToDelete completion:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    for (PFObject *object in self.currentGames) {
                        if ([object.objectId isEqualToString:gameToDelete.objectId]) {
                            [tempCurrentGames removeObject:object];
                            break;
                        }
                    }
                    
                    self.currentGames = tempCurrentGames;
                    [self.currentGamesTable reloadData]; // update table view
                    UIAlertView *alert = [[UIAlertView alloc]  initWithTitle:@"Game ended successfully." message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil,  nil];
                    [alert show];
                }
            }];
        }
        
        else if (indexPath.section == 1) { // current pending games section
            PFObject *gameToDelete = [self.currentPendingGames objectAtIndex:indexPath.row];
            NSMutableArray* tempCurrentPendingGames = [NSMutableArray arrayWithArray:self.currentPendingGames];
            
            [self.viewModel deleteGame:gameToDelete completion:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    for (PFObject *object in self.currentPendingGames) {
                        if ([object.objectId isEqualToString:gameToDelete.objectId]) {
                            [tempCurrentPendingGames removeObject:object];
                            break;
                        }
                    }
                    
                    self.currentPendingGames = tempCurrentPendingGames;
                    [self.currentGamesTable reloadData]; // update table view
                    UIAlertView *alert = [[UIAlertView alloc]  initWithTitle:@"Game deleted successfully." message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil,  nil];
                    [alert show];
                }
            }];
        }
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        // cancelled
        UITableViewCell* cell = [self.currentGamesTable cellForRowAtIndexPath:indexPath];
        cell.selected = NO;
    }]];
    
    alert.popoverPresentationController.sourceView = self.view;
    
    [self presentViewController:alert animated:YES
                     completion:nil];

}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"End game";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SnapScrambleCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    if(cell == nil)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    }
    
    // styling the cell
    UIFont *myFont = [UIFont fontWithName: @"Avenir Next" size: 18.0 ];
    cell.textLabel.font = myFont;
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    cell.detailTextLabel.minimumScaleFactor = 0.5;
    
    
    if (indexPath.section == 0) { // current games section
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        PFObject *aCurrentGame = [self.currentGames objectAtIndex:indexPath.row];
        NSDate *updated = [aCurrentGame updatedAt];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"EEE, MMM d, h:mm a"];

       
        // if current user is the receiver for the round
        if ([[aCurrentGame objectForKey:@"receiverName"]  isEqualToString:[PFUser currentUser].username]) {
            NSString *senderName = [aCurrentGame objectForKey:@"senderName"];
            cell.gameLabel.text = [NSString stringWithFormat:@"Your turn vs. %@", senderName];
            
            // check if it is the receiver's (the current user in this case) turn to reply or to play for the round
            if ([aCurrentGame objectForKey:@"receiverPlayed"] == [NSNumber numberWithBool:true]) {
                //cell.detailTextLabel.text = @"Your turn to reply";
                cell.timeLabel.text = @"Your turn to reply";
                cell.statusImage.image = [UIImage imageNamed:@"current-user-opened"];

            }
            else if ([aCurrentGame objectForKey:@"receiverPlayed"] == [NSNumber numberWithBool:false]) {
                //cell.detailTextLabel.text = @"Your turn to play";
                cell.timeLabel.text = [NSString stringWithFormat:@"Received on %@", [dateFormat stringFromDate:updated]];
                cell.statusImage.image = [UIImage imageNamed:@"current-user-received"];
            }
        }
    }
    
    if (indexPath.section == 1) { // pending games section
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        PFObject *aCurrentPendingGame = [self.currentPendingGames objectAtIndex:indexPath.row];
        NSDate *updated = [aCurrentPendingGame updatedAt];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"EEE, MMM d, h:mm a"];
        
        
        
        // if current user is the sender for the round
        if ([[aCurrentPendingGame objectForKey:@"senderName"]  isEqualToString:[PFUser currentUser].username]) {
            // delete if game had an error with assigning receiver
            if ([[aCurrentPendingGame objectForKey:@"receiverName"] isEqualToString:@""]) {
                NSMutableArray* tempCurrentPendingGames = [NSMutableArray arrayWithArray:self.currentPendingGames];
                [self.viewModel deleteGame:aCurrentPendingGame completion:^(BOOL succeeded, NSError *error) {
                    if (!error) {
                        NSLog(@"deleted game");
                        [tempCurrentPendingGames removeObject:aCurrentPendingGame];
                        self.currentPendingGames = tempCurrentPendingGames;
                        [tableView reloadData];
                    }
                    else {
                        NSLog(@"game failed to delete.");
                    }
                }];
            }
            
            // otherwise proceed
            else {
                NSString *opponentName = [aCurrentPendingGame objectForKey:@"receiverName"];
                cell.gameLabel.text = [NSString stringWithFormat:@"%@'s turn vs. You", opponentName];
                
                // check if it is the receiver's (not the current user in this case) turn to reply or to play for the round
                if ([aCurrentPendingGame objectForKey:@"receiverPlayed"] == [NSNumber numberWithBool:true]) {
                    //cell.detailTextLabel.text = @"Opponent's turn to reply";
                    cell.timeLabel.text = [NSString stringWithFormat:@"Opponent played on %@", [dateFormat stringFromDate:updated]];
                    cell.statusImage.image = [UIImage imageNamed:@"opponent-opened"];
                }
                else if ([aCurrentPendingGame objectForKey:@"receiverPlayed"] == [NSNumber numberWithBool:false]) {
                    //cell.detailTextLabel.text = @"Opponent's turn to play";
                    cell.timeLabel.text = [NSString stringWithFormat:@"Delivered on %@", [dateFormat stringFromDate:updated]];
                    cell.statusImage.image = [UIImage imageNamed:@"opponent-received"];

                }
            }
        }
    }
    
    return cell;
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self.currentGamesTable];
    NSIndexPath *indexPath = [self.currentGamesTable indexPathForRowAtPoint:p];
    UITableViewCell* cell = [self.currentGamesTable cellForRowAtIndexPath:indexPath];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        // get the cell at indexPath (the one you long pressed)
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.selected = YES;
        if (indexPath == nil){
            NSLog(@"couldn't find index path");
        } else {
            
            [self deleteGame:indexPath];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    
    // all of the current user's current games (current user is receiver here)
    if (indexPath.section == 0) {
        if (networkStatus == NotReachable) { // if there's no internet
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Woops!" message:@"Your device appears to not have an internet connection. Unfortunately Snap Scramble requires internet to play." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        }
        
        else {
            self.selectedGame = [self.currentGames objectAtIndex:indexPath.row];
            
            // if current user is the receiver for the round (just a safety check if statement)
            if ([[self.selectedGame objectForKey:@"receiverName"]  isEqualToString:[PFUser currentUser].username]) {
                self.opponent = [self.selectedGame objectForKey:@"sender"];
                
                if ([self.selectedGame objectForKey:@"receiverPlayed"] == [NSNumber numberWithBool:true]) { //  this is the condition if the game already exists but the receiver has yet to send back. he's already played.
                    [self performSegueWithIdentifier:@"createPuzzle" sender:self]; // if receiver (you) played, let you create another puzzle, play it, and send it
                }
                
                else if ([self.selectedGame objectForKey:@"receiverPlayed"] == [NSNumber numberWithBool:false]) { // if receiver (you) didn't play yet
                    [self performSegueWithIdentifier:@"startPuzzleScreen" sender:self];
                } //  we are going to have to get rid of this last part for new version.
            }
        }
    }
    
    // all of the user's pending games (user is sender here)
    else if (indexPath.section == 1) {
        if (networkStatus == NotReachable) {
            NSLog(@"There IS NO internet connection");
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Woops!" message:@"Your device appears to not have an internet connection. Unfortunately Snap Scramble requires internet to play." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        }
        
        else {
            self.selectedGame = [self.currentPendingGames objectAtIndex:indexPath.row];
            // do nothing currently, but in a next version display stats.
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"startPuzzleScreen"]) {
        StartPuzzleViewController *startPuzzleViewController = (StartPuzzleViewController *)segue.destinationViewController;
        startPuzzleViewController.delegate = self;
        startPuzzleViewController.createdGame = self.selectedGame;
        startPuzzleViewController.opponent = self.opponent;
        NSLog(@"Start puzzle screen opening...");
        NSLog(@"opponent: %@   current user selected this game: %@", self.opponent, self.selectedGame);
    }
    
    else if ([segue.identifier isEqualToString:@"showCamera"]) {
        //CameraViewController *cameraVC = (CameraViewController *)segue.destinationViewController;
        //cameraVC.modalTransitionStyle = UIModalTransitionStylePartialCurl;
        /* CreatePuzzleViewController *createPuzzleViewController = (CreatePuzzleViewController *)segue.destinationViewController;
        createPuzzleViewController.opponent = self.opponent;
        createPuzzleViewController.createdGame = self.selectedGame;
        NSLog(@"create puzzle screen opening... the current user has yet to start a new round by playing and sending back.");
        NSLog(@"opponent: %@   current user selected this game: %@", self.opponent, self.selectedGame); */
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

#pragma mark - delegate methods

- (void)receiveReplyGameData:(PFObject *)selectedGame andOpponent:(PFUser *)opponent andRound:(PFObject *)roundObject {
    self.opponent = opponent;
    self.selectedGame = selectedGame;
    self.roundObject = roundObject;
    
    NSLog(@"delegate success. replying... opponent: %@    game: %@", self.opponent, self.selectedGame);
    [self performSegueWithIdentifier:@"createPuzzle" sender:self]; // if receiver (you) played, let him create another puzzle + send it from CreatePuzzleVC
}
  

- (void)showSignupScreen {
    [self performSegueWithIdentifier:@"showSignup" sender:self];
}

@end
