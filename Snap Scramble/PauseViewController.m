//
//  PauseViewController.m
//  Snap Scramble
//
//  Created by Tim Gorer on 3/27/16.
//  Copyright © 2016 Tim Gorer. All rights reserved.
//

#import "PauseViewController.h"
#import "GameViewController.h"
#import "PauseViewModel.h"
#import "CameraViewController.h"
@import GoogleMobileAds;


@interface PauseViewController ()

@property(nonatomic, strong) PauseViewModel *viewModel;
@property(nonatomic, strong) GADInterstitial *interstitial;

@end

@implementation PauseViewController

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _viewModel = [[PauseViewModel alloc] init];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.resignButton addTarget:self action:@selector(resignButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
      [self.cancelButton addTarget:self action:@selector(cancelButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.reportButton addTarget:self action:@selector(reportButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
    self.cancelButton.adjustsImageWhenHighlighted = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.navigationController.navigationBar setHidden:true];
    self.reportButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.reportButton.titleLabel.minimumScaleFactor = 0.5;
    self.resignButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.resignButton.titleLabel.minimumScaleFactor = 0.5;
    self.solveLaterButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.solveLaterButton.titleLabel.minimumScaleFactor = 0.5;
    self.interstitial = [self createAndLoadInterstitial]; // load interstitial ad
}

- (GADInterstitial *)createAndLoadInterstitial {
    GADInterstitial *interstitial =
    [[GADInterstitial alloc] initWithAdUnitID:@"ca-app-pub-9099568248089334/6148429408"];
    interstitial.delegate = self;
    [interstitial loadRequest:[GADRequest request]];
    return interstitial;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelButtonDidPress:(id)sender {
    self.pauseView.animation = @"fall";
    self.pauseView.delay = 5.0;
    [self.pauseView animate];
    [self.game resume]; // resume the timer
    [self.navigationController popViewControllerAnimated:YES]; // pop like this
}

// delete the game if pressed
- (IBAction)resignButtonDidPress:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Game too hard?" message:@"Are you sure you want to delete this game? You may start a new one if this puzzle is too difficult." preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction: [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.viewModel deleteGame:self.createdGame completion:^(BOOL succeeded, NSError *error) {
            if (error) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred." message:@"Please try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alertView show];
            }
            
            else {
                NSLog(@"game deleted successfully.");
                [self displayAd];
                [self.navigationController popToRootViewControllerAnimated:YES]; // go to main menu
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

- (IBAction)reportButtonDidPress:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Report Inappropriate Content" message:@"Are you sure you want to report this user? Reporting them will also block them from sending anymore puzzles to you." preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction: [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // add code to report / block the user here
        self.blockedUsersRelation = [[PFUser currentUser] relationForKey:@"blockedUsers"];
        [self.blockedUsersRelation addObject:self.opponent];
        
        [self.viewModel saveCurrentUser:^(BOOL succeeded, NSError *error) {
            if (error) {
                NSLog(@"Error %@ %@", error, [error userInfo]);
            }
            
            else {
                NSLog(@"blocked users: %@", self.blockedUsersRelation);
            }
        }];
        
        
        NSString *blockedText = [@"Successfully blocked: " stringByAppendingString:self.opponent.username];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Blocked" message:blockedText delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        // cancelled
    }]];
    
    alert.popoverPresentationController.sourceView = self.view;
    
    [self presentViewController:alert animated:YES
                     completion:nil];
    
}


- (IBAction)finishSolvingLaterButtonDidPress:(id)sender {
    [self displayAd];
    for (UIViewController* viewController in self.navigationController.viewControllers) {
        if ([viewController isKindOfClass:[SwipeNavigationController class]] ) {
            SwipeNavigationController *VC = (SwipeNavigationController*)viewController;
            [self.navigationController popToViewController:VC animated:NO];
            CameraViewController* centerVC = (CameraViewController*)VC.centerViewController;
            [centerVC showLeftVC];

        }
    }}


- (void)displayAd{
    NSNumber *adsRemoved = [[NSUserDefaults standardUserDefaults] objectForKey:@"adsRemoved"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"%id", [adsRemoved boolValue]);
    if ([adsRemoved boolValue] != TRUE) {
        // show ad
        if (self.interstitial.isReady) {
            [self.interstitial presentFromRootViewController:self];
        } else {
            NSLog(@"Ad wasn't ready");
        }
    } else {
        NSLog(@"ads are removed for this user.");
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
