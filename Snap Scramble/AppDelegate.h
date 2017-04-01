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



@interface AppDelegate : UIResponder <UIApplicationDelegate, UNUserNotificationCenterDelegate,SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (strong, nonatomic) UIWindow *window;


@end

