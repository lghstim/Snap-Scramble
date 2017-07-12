//
//  ChallengeViewController.h
//  Snap Scramble
//
//  Created by Tim Gorer on 7/20/15.
//  Copyright (c) 2015 Tim Gorer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "SSPullToRefresh.h"
#import "Snap_Scramble-Swift.h"
@import GoogleMobileAds;
@class SwipeNavigationController;
@import SwipeNavigationController;


@protocol ChallengeVCDelegate <NSObject>
- (void)receiveReplyGameData:(PFObject *)selectedGame andOpponent:(PFUser *)opponent andRound:(PFObject *)roundObject;
@end

@interface ChallengeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, ChallengeVCDelegate>

@property (nonatomic, strong) NSArray *currentGames;
@property (nonatomic, strong) NSArray *currentPendingGames;
@property (nonatomic, strong) PFObject *selectedGame;
@property (nonatomic, strong) SSPullToRefreshView *refreshControl;
@property (nonatomic, strong) IBOutlet UITableView *currentGamesTable;
@property (nonatomic, strong) PFUser *opponent;
@property (nonatomic, strong) NSMutableArray *usernames;
@property(strong, nonatomic) NSMutableArray *images;
@property (strong, nonatomic) IBOutlet UIImageView *emptyTableScreen;
@property (nonatomic, strong)  DesignableLabel *usernameLabel;
@property (strong, nonatomic) DesignableButton *challengeButton;
@property (strong, nonatomic) DesignableButton *cameraButton;
@property (strong, nonatomic) UIImage *cameraImage;
@property (strong, nonatomic)  DesignableButton *removeAdsButton;
@property (nonatomic, strong)  UILabel *scoreLabel;
@property (nonatomic, strong) PFObject* roundObject;
@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;

// background view properties
@property (weak, nonatomic) IBOutlet UIView *backgroundView;

- (void)retrieveUserMatches;
- (void)updateScoreLabel;




@end
