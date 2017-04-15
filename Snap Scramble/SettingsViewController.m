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
@import Firebase;
@import SwipeNavigationController;

@interface SettingsViewController () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.clipsToBounds = TRUE;
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
                [PFUser logOut]; // log out current user
                [self.navigationController popToRootViewControllerAnimated:NO];
            }
        }];
    }
}

- (IBAction)goBackButtonDidPress:(id)sender {
     [self.containerSwipeNavigationController showCenterVCWithSwipeVC:self.containerSwipeNavigationController];
}

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
