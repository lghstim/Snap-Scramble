//
//  GameOverViewModel.m
//  Snap Scramble
//
//  Created by Tim Gorer on 8/4/16.
//  Copyright © 2016 Tim Gorer. All rights reserved.
//

#import "GameOverViewModel.h"

@implementation GameOverViewModel

- (void)updateGame {
    if ([[self.createdGame objectForKey:@"receiverName"] isEqualToString:[PFUser currentUser].username]) { // if current user is the receiver (we want the receiver to send back a puzzle). This code is executed when the user plays a game someone else sent him.
        [self.createdGame setObject:[NSNumber numberWithBool:true] forKey:@"receiverPlayed"]; // receiver played, set true
        [self.createdGame setObject:self.currentUserTotalSeconds forKey:@"receiverTime"]; // set the time
        NSLog(@"current user is the receiver. let him see stats, and then reply or end game. RECEIVER HAS PLAYED");
        [self.createdGame saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred." message:@"Please try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alertView show];
            }
            else {
                
                NSLog(@"game updated successfully: %@", self.createdGame);
            }
        }];
    }
    
    else if ([[self.createdGame objectForKey:@"senderName"] isEqualToString:[PFUser currentUser].username]) { // if current user is the sender. This code is executed when the user starts sending his own game to someone else.
        [self.createdGame setObject:[NSNumber numberWithBool:false] forKey:@"receiverPlayed"]; // set that the receiver has not played. i did this already in PreviewPuzzleVC, but I'm doing it again here to stop any confusion.
        [self.createdGame setObject:self.currentUserTotalSeconds forKey:@"senderTime"]; // set the time
        NSLog(@"current user is not the receiver, he's the sender. let him see stats, switch turns / send a push notification and then go to main menu to wait. RECEIVER HAS NOT PLAYED.");
        [self.createdGame saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred." message:@"Please try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alertView show];
            }
            else {
                NSLog(@"game updated successfully. %@", self.createdGame);
            }
        }];
    }
}

// save the game cloud object
- (void)saveCurrentGame:(void (^)(BOOL succeeded, NSError *error))completion {
    [self.createdGame saveInBackgroundWithBlock:completion];
}

// change the turn - make the receiver the opponent
- (void)switchTurns {
    [self.createdGame setObject:self.opponent.objectId forKey:@"receiverID"];
    [self.createdGame setObject:self.opponent.username forKey:@"receiverName"];
}

- (void)saveCurrentUser:(void (^)(BOOL succeeded, NSError *error))completion {
    [[PFUser currentUser] saveInBackgroundWithBlock:completion];
}

- (void)incrementWins {
    // update the amount of wins the opponent has.
    [PFCloud callFunctionInBackground:@"incrementWins" withParameters:@{@"userId": self.opponent.objectId} block:^(NSNumber *opponentWins, NSError *error) {
        if (error) {
            NSLog(@"error incrementing opponent's wins.");
        } else {
            NSLog(@"successfully incremented opponent's wins: %@", opponentWins);
        }
    }];
}

- (void)incrementLosses {
    // update the amount of losses the opponent has.
    [PFCloud callFunctionInBackground:@"incrementLosses" withParameters:@{@"userId": self.opponent.objectId} block:^(NSNumber *opponentLosses, NSError *error) {
        if (error) {
            NSLog(@"error incrementing opponent's losses.");
        } else {
            NSLog(@"successfully incremented opponent's losses: %@", opponentLosses);
        }
    }];
}


- (void)sendPushToOpponent {
    [PFCloud callFunctionInBackground:@"sendPushToOpponent" withParameters:@{@"userId": self.opponent.objectId} block:^(PFUser *opponent, NSError *error) {
        if (error) {
            NSLog(@"error sending push.");
        } else {
            NSLog(@"successfully sent push to: %@", opponent);
        }
    }];
}







@end
