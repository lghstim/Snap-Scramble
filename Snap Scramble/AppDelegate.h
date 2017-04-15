//
//  AppDelegate.h
//  Snap Scramble
//
//  Created by Tim Gorer on 7/20/15.
//  Copyright (c) 2015 Tim Gorer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <UserNotifications/UserNotifications.h>
#import "Snap_Scramble-Swift.h"
#import <SwipeNavigationController/SwipeNavigationController.h>
@import SwipeNavigationController;





@interface AppDelegate : UIResponder <UIApplicationDelegate, UNUserNotificationCenterDelegate>


@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) PFInstallation *installation;
@property (strong, nonatomic) SwipeNavigationController *swipeVC;




@end

