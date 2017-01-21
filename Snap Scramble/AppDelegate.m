//
//  AppDelegate.m
//  Snap Scramble
//
//  Created by Tim Gorer on 7/20/15.
//  Copyright (c) 2015 Tim Gorer. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse/Parse.h>
#import <Bolts/Bolts.h>
#import "ChallengeViewController.h"
#import "FriendsTableViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "OnboardingViewController.h"
#import "OnboardingContentViewController.h"
#import "SignupViewController.h"
@import Firebase;



static NSString * const kUserHasOnboardedKey = @"user_has_onboarded";



@interface AppDelegate ()

@end

@import UIKit;

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
   self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    // determine if the user has onboarded yet or not
    BOOL userHasOnboarded = [[NSUserDefaults standardUserDefaults] boolForKey:kUserHasOnboardedKey];
    
    // if the user has already onboarded, just set up the normal root view controller
    // for the application
    if (userHasOnboarded) {
        [self setupNormalRootViewController];
    }
    
    // otherwise set the root view controller to the onboarding view controller
    else {
        self.window.rootViewController = [self generateStandardOnboardingVC];
    }
    
    application.statusBarStyle = UIStatusBarStyleLightContent;
    
    [Parse initializeWithConfiguration:[ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {
     configuration.applicationId = @"TIMZlKrUJamuyrJjCwZUMZvw2fazOQTNLr42KRK1";
     configuration.clientKey = @"hoG9ypisimFCmPstjHcEYfK6g9DoJU0qrY9sTS8X";
        configuration.server = @"https://pacific-harbor-61840.herokuapp.com/parse";
     }]];
    
    [FIRApp configure];
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
  
    // Register for Push Notitications, if running iOS 8
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                        UIUserNotificationTypeBadge |
                                                        UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                                 categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    }

    
    // Use the product identifier from iTunes to register a handler.
    [PFPurchase addObserverForProduct:@"com.timgorer.SnapScrambleDescrambleFriends.SnapScramblePremiumApp" block:^(SKPaymentTransaction *transaction) {
        // Write business logic that should run once this product is purchased.
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setBool:true forKey:@"premiumUser"];
        [userDefaults synchronize];
    }];

    
    [self.window makeKeyAndVisible];
    
    return YES;
}


- (void)setupNormalRootViewController {
    // create whatever your root view controller is going to be, in this case just a simple view controller
    // wrapped in a navigation controller
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main"
                                                             bundle: nil];
    
    UINavigationController *controller = (UINavigationController*)[mainStoryboard
                                                                   instantiateViewControllerWithIdentifier: @"navSnap"];
    self.window.rootViewController = controller;
}

- (void)handleOnboardingCompletion {
    // set that we have completed onboarding so we only do it once... for demo

   [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserHasOnboardedKey];
    
    // transition to the main application
    [self setupNormalRootViewController];
}

- (OnboardingViewController *)generateStandardOnboardingVC {
    OnboardingContentViewController *firstPage = [OnboardingContentViewController contentWithTitle:@"Welcome to Snap Scramble" body:@"Snap Scramble is an awesome social jigsaw puzzle game for iPhone!" image:nil buttonText:nil action:nil];
    
    OnboardingContentViewController *secondPage = [OnboardingContentViewController contentWithTitle:@"Create a game" body:@"Choose from your friends list or play with a random opponent." image:nil buttonText:nil action:nil];
   
    
    OnboardingContentViewController *thirdPage = [OnboardingContentViewController contentWithTitle:@"Select a photo" body:@"Snap a picture or choose from your photo library." image:nil buttonText:nil action:nil];
    
    OnboardingContentViewController *fourthPage = [OnboardingContentViewController contentWithTitle:@"Choose a puzzle size" body:@"Available sizes: 4 x 4, 5 x 5, or 6 x 6." image:nil buttonText:nil action:nil];

    
    OnboardingContentViewController *fifthPage = [OnboardingContentViewController contentWithTitle:@"Solve the jigsaw puzzle as fast as possible." body:@"The person with the fastest time wins that round." image:nil buttonText:nil action:nil];
    
    OnboardingContentViewController *sixthPage = [OnboardingContentViewController contentWithTitle:@"Quick tip:" body:@"Correctly placed pieces lock into place." image:nil buttonText:@"Get Started" action:^{
        [self handleOnboardingCompletion];
    }];
    
    
    
    OnboardingViewController *onboardingVC = [OnboardingViewController onboardWithBackgroundImage:[UIImage imageNamed:@"iphone-onboard"] contents:@[firstPage, secondPage, thirdPage, fourthPage, fifthPage, sixthPage]];
    onboardingVC.shouldFadeTransitions = YES;
    onboardingVC.fadePageControlOnLastPage = YES;
    onboardingVC.fadeSkipButtonOnLastPage = YES;
    
    
    return onboardingVC;
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *installation = [PFInstallation currentInstallation];
    [installation setDeviceTokenFromData:deviceToken];
    installation.channels = @[ @"global" ];
    [installation saveInBackground];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadTheTable" object:nil];
    [PFPush handlePush:userInfo];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    //[self stopRandomUserSearch]; // stop user from being searched for if he closes the app.
}



- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [FBSDKAppEvents activateApp];
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveInBackground];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    if ([shortcutItem.type isEqualToString:@"com.timgorer.SnapScrambleDescrambleFriends.addFriends"]) {
        NSLog(@"%@", shortcutItem.type);
        UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        FriendsTableViewController *friendsVC = (FriendsTableViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"FriendsVC"];
        [navigationController pushViewController:friendsVC animated:YES];
    }
}



@end
