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
#import "Snap_Scramble-Swift.h"
#import "LoginViewController.h"
#import "ChallengeViewController.h"
@import Firebase;
@import SwipeNavigationController;

@interface SettingsViewController () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@end

@implementation SettingsViewController

# pragma mark - view methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.clipsToBounds = TRUE;
    [self.logoutButton addTarget:self action:@selector(logoutButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
    self.goBackButton.adjustsImageWhenHighlighted = YES;
    self.view.backgroundColor = [self colorWithHexString:@"71C7F0"];
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

# pragma mark - navigation methods

- (IBAction)logoutButtonDidPress:(id)sender {
    [KVNProgress showWithStatus:@"Logging out..."]; // UI
    // this is for resetting the key necessary for push notifications on logout.
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        [[PFInstallation currentInstallation] removeObjectForKey:@"User"]; // reset "User" key
        [[PFInstallation currentInstallation] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (error) {
                NSLog(@"error resetting PFInstallation 'User' key");
                [KVNProgress dismiss];
            } else {
                [NSThread sleepForTimeInterval:2];
                [KVNProgress dismiss];
                [self showLoginVC];
                [PFUser logOut]; // log out current user
            
            }
        }];
    }
}

- (IBAction)goBackButtonDidPress {
     [self.containerSwipeNavigationController showCenterVCWithSwipeVC:self.containerSwipeNavigationController];
}

- (void)showLoginVC {
    [self.containerSwipeNavigationController showLeftVCWithSwipeVC:self.containerSwipeNavigationController];
    ChallengeViewController *challengeVC = (ChallengeViewController*)self.containerSwipeNavigationController.leftViewController;
    [challengeVC performSegueWithIdentifier:@"showSignup" sender:challengeVC];
}

- (IBAction)shareButtonDidPress:(id)sender {
    [FIRAnalytics logEventWithName:kFIREventSelectContent
                        parameters:@{
                                     kFIRParameterItemID:[NSString stringWithFormat:@"id-%@", self.title],
                                     kFIRParameterItemName:@"share-button-pressed",
                                     kFIRParameterContentType:@"image"
                                     }];
    
    
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

# pragma mark - remove ads (in-app purchase) methods

- (IBAction)restore{
    //this is called when the user restores purchases, you should hook this up to a button
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSLog(@"received restored transactions: %lu", (unsigned long)queue.transactions.count);
    for(SKPaymentTransaction *transaction in queue.transactions){
        if(transaction.transactionState == SKPaymentTransactionStateRestored){
            //called when the user successfully restores a purchase
            NSLog(@"Transaction state -> Restored");
            
            //if you have more than one in-app purchase product,
            //you restore the correct product for the identifier.
            //For example, you could use
            //if(productID == kRemoveAdsProductIdentifier)
            //to get the product identifier for the
            //restored purchases, you can use
            //
            //NSString *productID = transaction.payment.productIdentifier;
            //[self displayTransactionRestored];
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:TRUE] forKey:@"adsRemoved"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self displayTransactionRestored];
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            break;
        }
    }
}

- (void)displayTransactionRestored {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"We restored your purchase." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alertView show];
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



@end
