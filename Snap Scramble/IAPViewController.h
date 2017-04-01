//
//  IAPViewController.h
//  
//
//  Created by Tim Gorer on 1/5/17.
//
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "Snap_Scramble-Swift.h"
#import <StoreKit/StoreKit.h>


@interface IAPViewController : UIViewController 

@property (weak, nonatomic) IBOutlet SpringView *IAPView;
@property (weak, nonatomic) IBOutlet UILabel *IAPlabel;
- (IBAction)goBackButtonDidPress:(id)sender;


@end
