//
//  SettingsViewController.m
//  Snap Scramble
//
//  Created by Tim Gorer on 4/4/16.
//  Copyright © 2016 Tim Gorer. All rights reserved.
//

#import "SettingsViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>
#import "IAPViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.logoutButton addTarget:self action:@selector(logoutButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.goBackButton addTarget:self action:@selector(goBackButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
    self.goBackButton.adjustsImageWhenHighlighted = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.navigationController.navigationBar setHidden:true];
    self.logoutButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.logoutButton.titleLabel.minimumScaleFactor = 0.5;
    self.termsAndConditionsButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.termsAndConditionsButton.titleLabel.minimumScaleFactor = 0.5;
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

- (IBAction)logoutButtonDidPress:(id)sender {
    // this is for resetting the key necessary for push notifications on logout.
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        [[PFInstallation currentInstallation] removeObjectForKey:@"User"]; // reset "User" key
        [[PFInstallation currentInstallation] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (error) {
                NSLog(@"error resetting PFInstallation 'User' key");
            } else {
                [PFUser logOut]; // log out current user
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
        }];
    }
}

- (IBAction)goBackButtonDidPress:(id)sender {
    self.settingsView.animation = @"fall";
    [self.settingsView animate];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)unlockFullVersionButtonDidPress:(id)sender {
    // performs the chooseToBuyIAP segue
}

- (IBAction)restorePurchasesButtonDidPress:(id)sender {
    [PFPurchase restore];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults boolForKey:@"premiumUser"] != true) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"No purchases to restore" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
    } else if ([userDefaults boolForKey:@"premiumUser"] == true) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"Snap Scramble Premium restored." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
    }
}

- (IBAction)shareButtonDidPress:(id)sender {
    NSString *textToShare = @"Check out the iPhone game Snap Scramble!";
    NSURL *myWebsite = [NSURL URLWithString:@"https://itunes.apple.com/us/app/snap-scramble-descramble-photos/id1099409958?mt=8"];
    
    NSArray *objectsToShare = @[textToShare, myWebsite];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
    
    NSArray *excludeActivities = @[UIActivityTypeAirDrop,
                                   UIActivityTypePrint,
                                   UIActivityTypeAssignToContact,
                                   UIActivityTypeSaveToCameraRoll,
                                   UIActivityTypeAddToReadingList,
                                   UIActivityTypePostToFlickr,
                                   UIActivityTypePostToVimeo];
    
    activityVC.excludedActivityTypes = excludeActivities;
    [self presentViewController:activityVC animated:YES completion:nil];
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"chooseToBuyIAP"]) {
        IAPViewController *viewController = (IAPViewController *)segue.destinationViewController;
        viewController.IAPlabel.text = @"The full version doesn't have the 10 game limit that the free version has.";
    }
}


@end
