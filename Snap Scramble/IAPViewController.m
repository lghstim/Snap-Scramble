//
//  IAPViewController.m
//  
//
//  Created by Tim Gorer on 1/5/17.
//
//

#import "IAPViewController.h"

@interface IAPViewController ()

@end

@implementation IAPViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationController.navigationBar setHidden:true];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)goBackButtonDidPress:(id)sender {
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

@end
