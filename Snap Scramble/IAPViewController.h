//
//  IAPViewController.h
//  
//
//  Created by Tim Gorer on 1/5/17.
//
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>


@interface IAPViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *IAPlabel;
- (IBAction)goBackButtonDidPress:(id)sender;
- (IBAction)unlockFullVersionButtonDidPress:(id)sender;


@end
