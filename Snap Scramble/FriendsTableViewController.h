//
//  FriendsTableViewController.h
//  Snap Scramble
//
//  Created by Tim Gorer on 3/5/16.
//  Copyright © 2016 Tim Gorer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <KVNProgress/KVNProgress.h>
#import "UserSelectionViewController.h"
#import "SSPullToRefresh.h"


@class UserSelectionViewController;

@interface FriendsTableViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) id<UserSelectVCDelegate> delegate;
@property (nonatomic, strong) PFUser *opponent;
@property (nonatomic, strong) PFRelation *friendsRelation;
@property (nonatomic, strong) NSArray *friends;
@property (nonatomic, strong) NSMutableArray *mutableFriendsList;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addFriendBarButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *goBackButton;
@property (nonatomic, strong) NSTimer *timeoutTimer;
@property (nonatomic, strong) NSNumber* totalSeconds;
@property (nonatomic, strong) IBOutlet UITableView *currentFriendsTable;
@property (nonatomic, strong) SSPullToRefreshView *refreshControl;
@property (weak, nonatomic) IBOutlet UIView *backgroundView;





@end
