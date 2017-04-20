//
//  SettingsViewController.h
//  Snap Scramble
//
//  Created by Tim Gorer on 4/4/16.
//  Copyright © 2016 Tim Gorer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Snap_Scramble-Swift.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>
#import <KVNProgress/KVNProgress.h>


@interface SettingsViewController : UIViewController 

@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UIButton *termsAndConditionsButton;
@property (weak, nonatomic) IBOutlet UIButton* goBackButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet SpringView *settingsView;
@property (nonatomic, strong) NSTimer *timeoutTimer;
@property (nonatomic, strong) NSNumber* totalSeconds;

- (IBAction)shareButtonDidPress:(id)sender;
- (void)goBackButtonDidPress;

@end

