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

# pragma mark - view methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.bannerView.rootViewController = self;
    self.view.clipsToBounds = TRUE;
    self.currentGamesTable.delegate = self;
    self.currentGamesTable.dataSource = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTable:) name:@"reloadTheTable" object:nil]; // reload the table if the user receives a notification?
    [self setNavigationBar];
    self.refreshControl = [[SSPullToRefreshView alloc] initWithScrollView:self.currentGamesTable delegate:self];
    [self.currentGamesTable addSubview:self.refreshControl];
    self.currentGamesTable.delaysContentTouches = NO;

    
    
    UINib *nib = [UINib nibWithNibName:@"SnapScrambleCell" bundle:nil];
    [[self currentGamesTable] registerNib:nib forCellReuseIdentifier:@"Cell"];

    // initialize a view for displaying the empty table screen if a user has no games.
    self.emptyTableScreen = [[UIImageView alloc] init];

    // check for internet connection, send a friendly message.
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    
    if (networkStatus == NotReachable) { // if there's no internet
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Woops!" message:@"Your device appears to not have an internet connection. Unfortunately Snap Scramble requires internet to play." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
    }
    
    // camera button UI
    _cameraButton = [DesignableButton new];
    self.cameraImage = [UIImage imageNamed:@"take-photo"];
    [self.cameraButton setImage:self.cameraImage forState:UIControlStateNormal];
    
    [self.view addSubview:self.cameraButton];
    [self.cameraButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-55.f);
    }];
    
    [self.view bringSubviewToFront:self.cameraButton];
    [self.cameraButton addTarget:self action:@selector(playButtonDidPress:) forControlEvents:UIControlEventTouchDown];
    [self.cameraButton addTarget:self action:@selector(animatePlayButton:) forControlEvents:UIControlEventTouchDown];
    [self.cameraButton setImage:[self imageByApplyingAlpha:0.6] forState:UIControlStateHighlighted];
   // [self setUIButtonsAndLabels];

    PFUser *currentUser = [PFUser currentUser];
    NSLog(@"current user %@", currentUser);
    if (currentUser) {
        NSLog(@"Current userrr: %@", currentUser.username);
        [self.currentGamesTable reloadData]; // reload the table view
        [self retrieveUserMatches]; // retrieve all games, both pending and current
        NSString* usernameText = @"Username: ";
        usernameText = [usernameText stringByAppendingString:currentUser.username];
        [self.usernameLabel setText:usernameText];
        [[PFInstallation currentInstallation] setObject:[PFUser currentUser] forKey:@"User"];
        [[PFInstallation currentInstallation] saveInBackground];
    }
    
    else {
        [self showSignupScreen]; // show sign up screen if user not signed in
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.refreshControl = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reallocateVars];
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        NSLog(@"Current userr: %@", currentUser.username);
        [self.currentGamesTable reloadData]; // reload the table view
        [self retrieveUserMatches]; // retrieve all games, both pending and current
        NSString* usernameText = @"Username: ";
        usernameText = [usernameText stringByAppendingString:currentUser.username];
        [self.usernameLabel setText:usernameText];
        [[PFInstallation currentInstallation] setObject:[PFUser currentUser] forKey:@"User"];
        [[PFInstallation currentInstallation] saveInBackground];
    }
    
    else {
        [self showSignupScreen]; // show sign up screen if user not signed in
    }
    
    [self setUpLongPressCell];
    [self displayAd]; // display ad, or not if user paid
    [[UIApplication sharedApplication] setStatusBarHidden:NO];

}


-(void)viewWillDisappear:(BOOL)animated {
    [self.currentGamesTable reloadData];
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        [self retrieveUserMatches];
    }
}
    
- (void)reallocateVars{
    self.opponent = nil;
    self.selectedGame = nil;
    self.roundObject = nil;
    self.cameraImage = nil;
     CameraViewController *cameraVC = ((AppDelegate *)[UIApplication sharedApplication].delegate).centerVC;
    [cameraVC deallocate];
    CreatePuzzleViewController *createVC = ((AppDelegate *)[UIApplication sharedApplication].delegate).bottomVC;
    [createVC deallocate];
}

/* - (void)setUIButtonsAndLabels {
    // username label
    _usernameLabel = [DesignableLabel new];
    self.usernameLabel.text = [NSString stringWithFormat:@"Current user: %@",  [PFUser currentUser].username];
    self.usernameLabel.font = [UIFont fontWithName:@"Avenir Next" size:18];
    self.usernameLabel.textAlignment = NSTextAlignmentCenter;
    [self.usernameLabel setTextColor:[self colorWithHexString:@"71C7F0"]];
    [self.usernameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@200);
        make.centerX.equalTo(self.headerView);
        make.top.equalTo(self.headerView).offset(50);
    }];
    self.usernameLabel.adjustsFontSizeToFitWidth = YES;
    self.usernameLabel.contentScaleFactor = 1.0;
    [self.headerView bringSubviewToFront:self.usernameLabel];
    [self.usernameLabel setFrame:CGRectIntegral(self.usernameLabel.frame)];
    
    // score label
    _scoreLabel = [UILabel new];
    self.scoreLabel.text =  [NSString stringWithFormat:@"Wins: 0 | Losses: 0"];    [self.headerView addSubview:self.scoreLabel];
    self.scoreLabel.font = [UIFont fontWithName:@"AvenirNext" size:19];
    self.scoreLabel.textAlignment = NSTextAlignmentCenter;
    [self.scoreLabel setTextColor:[self colorWithHexString:@"71C7F0"]];
    [self.headerView addSubview:self.scoreLabel];
    [self.scoreLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerView);
        make.top.equalTo(self.headerView).offset(30);
    }];
    [self.headerView bringSubviewToFront:self.scoreLabel];
    [self.scoreLabel setFrame:CGRectIntegral(self.scoreLabel.frame)];
} */

- (void)askToRemoveAds {
    NSNumber *adsRemoved = [[NSUserDefaults standardUserDefaults] objectForKey:@"adsRemoved"];
    NSNumber *wantsToRemoveAds = [[NSUserDefaults standardUserDefaults] objectForKey:@"wantsToRemoveAds"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"%id", [adsRemoved boolValue]);
    NSInteger countOne = [self.currentGames count];
    NSInteger countTwo = [self.currentPendingGames count];
    NSNumber *gameCount = [NSNumber numberWithInteger:countOne + countTwo];
    int gameCountInt = [gameCount intValue];
    NSLog(@"game count: %d", gameCountInt);
    if ([adsRemoved boolValue] != TRUE && gameCountInt >= 10 && [wantsToRemoveAds  boolValue] != FALSE) {
        NSLog(@"hiiiii");
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Remove ads?" message:@"You seem to be enjoying Snap Scramble. Would you like to remove ads for $1.99?" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction: [UIAlertAction actionWithTitle:@"Yes!" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self goToIAPVC:self];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            // cancelled
            NSLog(@"wtf");
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:FALSE] forKey:@"wantsToRemoveAds"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }]];
        alert.popoverPresentationController.sourceView = self.view;
        [self presentViewController:alert animated:YES
                         completion:nil];
    } else {
        // user already has ads removed
    }
}

- (void)setNavigationBar {
    UINavigationBar *navbar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 65)];
    navbar.backgroundColor = [self colorWithHexString:@"71C7F0"];
    navbar.barTintColor = [self colorWithHexString:@"71C7F0"];
    navbar.layer.cornerRadius = 5;
    navbar.layer.masksToBounds = YES;
    UINavigationItem* navItem = [[UINavigationItem alloc] initWithTitle:@"Snap Scramble"];
    [navItem.titleView setFrame:CGRectMake(navItem.titleView.frame.origin.x, navItem.titleView.frame.origin.y + 30, navItem.titleView.frame.size.width, navItem.titleView.frame.size.height)];
    [navbar setItems:@[navItem]];
    [self.view addSubview:navbar];
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (void)displayAd{
    NSNumber *adsRemoved = [[NSUserDefaults standardUserDefaults] objectForKey:@"adsRemoved"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"%id", [adsRemoved boolValue]);
    if ([adsRemoved boolValue] != TRUE) {
        self.bannerView.adUnitID = @"ca-app-pub-9099568248089334/4082940202";
        GADRequest *request = [GADRequest request];
        //request.testDevices = @[@"117d8d0d0cfc555fabc2f06fb83770b8"];
        [self.bannerView loadRequest:request];
    } else {
        NSLog(@"ads are removed for this user.");
        self.bannerView.hidden = YES;
    }
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

/* - (void)displayAdsButton {
    NSNumber *adsRemoved = [[NSUserDefaults standardUserDefaults] objectForKey:@"adsRemoved"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"%id", [adsRemoved boolValue]);
    if ([adsRemoved boolValue] != TRUE) {
        _removeAdsButton = [DesignableButton new];
        [self.removeAdsButton setTitle:@"Press here to remove ads for $1.99" forState:UIControlStateNormal];
        [self.removeAdsButton setTitleColor:[self colorWithHexString:@"71C7F0"] forState:UIControlStateNormal];
        self.removeAdsButton.titleLabel.font = [UIFont fontWithName:@"Avenir Next" size:18];
        self.removeAdsButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.removeAdsButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.headerView);
            make.topMargin.equalTo(@5);
        }];
        self.removeAdsButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.removeAdsButton.titleLabel.contentScaleFactor = 1.0;
        [self.removeAdsButton addTarget:self action:@selector(goToIAPVC:) forControlEvents:UIControlEventTouchUpInside];
        [self.removeAdsButton setImage:[self imageByApplyingAlpha:0.6] forState:UIControlStateHighlighted];
    } else {
        self.removeAdsButton.hidden = TRUE;
    }
} */

# pragma mark - pull to refresh methods

- (void)pullToRefreshViewDidStartLoading:(SSPullToRefreshView *)view {
    [self retrieveUserMatches];
}


# pragma mark - navigation

- (void)playButtonDidPress:(id)sender {
   [self.containerSwipeNavigationController showCenterVCWithSwipeVC:self.containerSwipeNavigationController];
    [self passNewGameDataToCameraVC];
}

- (void)animatePlayButton:(id)sender {
    self.challengeButton.animation = @"pop";
    [self.challengeButton animate];
}

- (IBAction)goToIAPVC:(id)sender {
    [self.containerSwipeNavigationController showCenterVCWithSwipeVC:self.containerSwipeNavigationController];
    SettingsViewController *settingsVC = (SettingsViewController*)self.containerSwipeNavigationController.topViewController;
    [settingsVC performSegueWithIdentifier:@"openRemoveAds" sender:settingsVC];
}

- (void)goToCameraVC {
    [self.containerSwipeNavigationController showCenterVCWithSwipeVC:self.containerSwipeNavigationController];
    [self passSelectedGameDataToCameraVC];
}

- (void)goToStartPuzzleVC {
    [self performSegueWithIdentifier:@"startPuzzleScreen" sender:self];
}

- (void)showSignupScreen {
    [self performSegueWithIdentifier:@"showSignup" sender:self];
}

#pragma mark - currentGamesTable (UITableView) methods logic

- (void)retrieveUserMatches {
    // retrieve current matches
    [self.refreshControl startLoading];
    [self.viewModel retrieveCurrentMatches:^(NSArray *matches, NSError *error) {
        if (error) {
            NSLog(@"Error %@ %@", error, [error userInfo]);
        }
        
        else {
            self.currentGames = matches;
            [self.currentGamesTable reloadData];
            
            // then retrieve pending matches
            [self.viewModel retrievePendingMatches:^(NSArray *matches, NSError *error) {
                if (error) {
                    NSLog(@"Error %@ %@", error, [error userInfo]);
                }
                
                else {
                    [self.refreshControl finishLoading];
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
                    [self goToCameraVC];
                }
                
                else if ([self.selectedGame objectForKey:@"receiverPlayed"] == [NSNumber numberWithBool:false]) { // if receiver (you) didn't play yet
                    [self goToStartPuzzleVC];
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

- (void)setUpLongPressCell {
    // attach long press gesture to collectionView
    UILongPressGestureRecognizer *lpgr
    = [[UILongPressGestureRecognizer alloc]
       initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.delegate = self;
    lpgr.delaysTouchesBegan = YES;
    [self.currentGamesTable addGestureRecognizer:lpgr];
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

- (void)reloadTable:(NSNotification *)notification {
    [self retrieveUserMatches];
}

# pragma mark - pass data methods

// pass data to StartPuzzleVC
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"startPuzzleScreen"]) {
        StartPuzzleViewController *startPuzzleViewController = (StartPuzzleViewController *)segue.destinationViewController;
        startPuzzleViewController.delegate = self;
        startPuzzleViewController.createdGame = self.selectedGame;
        startPuzzleViewController.opponent = self.opponent;
        NSLog(@"Start puzzle screen opening...");
        NSLog(@"opponent: %@   current user selected this game: %@", self.opponent, self.selectedGame);
    }
}

- (void)passSelectedGameDataToCameraVC {
    CameraViewController *cameraVC = ((AppDelegate *)[UIApplication sharedApplication].delegate).centerVC;
    cameraVC.opponent = self.opponent;
    NSLog(@"%@", cameraVC.opponent);
    cameraVC.createdGame = self.selectedGame;
}

- (void)passNewGameDataToCameraVC {
    CameraViewController *cameraVC = ((AppDelegate *)[UIApplication sharedApplication].delegate).centerVC;
    cameraVC.opponent = nil;
    cameraVC.createdGame = nil;
}


- (void)dealloc {
    self.opponent = nil;
    self.selectedGame = nil;
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

- (UIImage *)imageByApplyingAlpha:(CGFloat) alpha {
    UIGraphicsBeginImageContextWithOptions(self.cameraImage.size, NO, 0.0f);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, self.cameraImage.size.width, self.cameraImage.size.height);
    
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);
    
    CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
    
    CGContextSetAlpha(ctx, alpha);
    
    CGContextDrawImage(ctx, area, [self.cameraImage CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

#pragma mark - delegate methods

- (void)receiveReplyGameData:(PFObject *)selectedGame andOpponent:(PFUser *)opponent andRound:(PFObject *)roundObject {
    self.opponent = opponent;
    self.selectedGame = selectedGame;
    self.roundObject = roundObject;
    
    NSLog(@"delegate success. replying... opponent: %@    game: %@", self.opponent, self.selectedGame);
    [self.containerSwipeNavigationController showCenterVCWithSwipeVC:self.containerSwipeNavigationController]; // if receiver (you) played, let him create another puzzle + send it from CreatePuzzleVC
}
  


@end
