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
@import Firebase;

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
    self.settingsView.animation = @"fall";
    [self.settingsView animate];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)restore{
    //this is called when the user restores purchases, you should hook this up to a button
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
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
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            break;
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{
    for(SKPaymentTransaction *transaction in transactions){
        //if you have multiple in app purchases in your app,
        //you can get the product identifier of this transaction
        //by using transaction.payment.productIdentifier
        //
        //then, check the identifier against the product IDs
        //that you have defined to check which product the user
        //just purchased
        BOOL areAdsRemoved = NO;
        switch(transaction.transactionState){
            case SKPaymentTransactionStatePurchasing: NSLog(@"Transaction state -> Purchasing");
                //called when the user is in the process of purchasing, do not add any of your own code here.
                break;
            case SKPaymentTransactionStatePurchased:
                //this is called when the user has successfully purchased the package (Cha-Ching!)
                areAdsRemoved = YES;
                [[NSUserDefaults standardUserDefaults] setBool:areAdsRemoved forKey:@"adsRemoved"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                NSLog(@"Transaction state -> Purchased");
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"Transaction state -> Restored");
                areAdsRemoved = YES;
                [[NSUserDefaults standardUserDefaults] setBool:areAdsRemoved forKey:@"adsRemoved"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                //called when the transaction does not finish
                if(transaction.error.code == SKErrorPaymentCancelled){
                    NSLog(@"Transaction state -> Cancelled");
                    //the user cancelled the payment ;(
                }
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
        }
    }
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
