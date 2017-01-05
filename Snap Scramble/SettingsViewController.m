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

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL =
    [NSURL URLWithString:@"https://itunes.apple.com/us/app/snap-scramble-descramble-photos/id1099409958?mt=8"];
    content.contentTitle = @"Download Snap Scramble";
    content.contentDescription = @"Check out the iPhone game Snap Scramble!";
    self.facebookSendButton.titleLabel.text = @"Share through Facebook Messenger";
    self.facebookSendButton.shareContent = content;
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
    [PFUser logOut]; // log out current user
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)goBackButtonDidPress:(id)sender {
    self.settingsView.animation = @"fall";
    [self.settingsView animate];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)unlockFullVersionButtonDidPress:(id)sender {
    [PFPurchase buyProduct:@"com.timgorer.SnapScrambleDescrambleFriends.SnapScramblePremiumApp" block:^(NSError *error) {
        if (!error) {
            // Run UI logic that informs user the product has been purchased, such as displaying an alert view.
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
        
        else {
            NSLog(@"hi: %@", error);
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred in purchasing Snap Scramble Premium." message:@"Please try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alertView show];
        }
    }];
}

- (IBAction)restorePurchasesButtonDidPress:(id)sender {
    [PFPurchase restore];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults boolForKey:@"premiumUser"] != true) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"No purchases to restore" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alertView show];
    } else if ([userDefaults boolForKey:@"premiumUser"] == true) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"Snap Scramble Premium restored." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alertView show];
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
