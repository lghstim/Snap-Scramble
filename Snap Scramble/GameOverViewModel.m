//
//  GameOverViewModel.m
//  Snap Scramble
//
//  Created by Tim Gorer on 8/4/16.
//  Copyright © 2016 Tim Gorer. All rights reserved.
//

#import "GameOverViewModel.h"

@implementation GameOverViewModel

- (void)updateGame:(void (^)(BOOL succeeded, NSError *error))completion {
    if ([[self.createdGame objectForKey:@"receiverName"] isEqualToString:[PFUser currentUser].username]) { // if current user is the receiver (we want the receiver to send back a puzzle). This code is executed when the user plays a game someone else sent him.
        [self.createdGame setObject:[NSNumber numberWithBool:true] forKey:@"receiverPlayed"]; // receiver played, set true
        [self.createdGame setObject:self.currentUserTotalSeconds forKey:@"receiverTime"]; // set the time
        NSNumber *currentRoundNumber = [self.createdGame objectForKey:@"roundNumber"];          // get the current round number

        [self getRoundObject:^(PFObject *round, NSError *error) { // get current round object with matching round number
            if (error) {
                NSLog(@"error");
            } else {
                self.roundObject = round;
                NSLog(@"current round number: %@    current round object: %@", [self.roundObject objectForKey:@"roundNumber"], self.roundObject);
                
                [self.roundObject setObject:self.currentUserTotalSeconds forKey:@"receiverTime"]; // set the time for the round
                NSLog(@"current user is the receiver. let him see stats, and then reply or end game. RECEIVER HAS PLAYED");
                [self.roundObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (error) {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred." message:@"Please try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                        [alertView show];
                    }
                    else {
                        [self.roundsRelation addObject:self.roundObject]; // add the round object to the game's rounds relation
                        NSLog(@"round saved successfully. %@", self.roundObject);
                        [self.createdGame saveInBackgroundWithBlock:completion]; // save game
                    }
                }];
            }
        } whereRoundNumberIs:currentRoundNumber];
        
    }
    

    if ([[self.createdGame objectForKey:@"senderName"] isEqualToString:[PFUser currentUser].username]) { // if current user is the sender. This code is executed when the user starts sending his own game to someone else.
        
        [self.createdGame setObject:[NSNumber numberWithBool:false] forKey:@"receiverPlayed"]; // set that the receiver has not played. i did this already in PreviewPuzzleVC, but I'm doing it again here to stop any confusion.
        
        self.roundObject = [PFObject objectWithClassName:@"Round"];         // create a new round object
        [self.roundObject setObject:self.currentUserTotalSeconds forKey:@"senderTime"]; // set the round time
        [self.createdGame setObject:self.currentUserTotalSeconds forKey:@"senderTime"]; // set the time
        [self.roundObject setObject:self.opponent.username forKey:@"receiverName"]; // set opponent to receiver
        [self.roundObject setObject:[PFUser currentUser].username forKey:@"senderName"]; // set opponent to receiver
        [self.createdGame setObject:[PFUser currentUser].username forKey:@"senderName"]; // set current user to sender
        NSNumber *roundNumber = [self.createdGame objectForKey:@"roundNumber"];
        int roundNumberInt = [roundNumber intValue];
        [self.roundObject setObject:[NSNumber numberWithInt:roundNumberInt + 1] forKey:@"roundNumber"]; // increment the round object roundNumber
        [self.createdGame setObject:[NSNumber numberWithInt:roundNumberInt + 1] forKey:@"roundNumber"]; // increment the game key roundNumber
         NSLog(@"round number on creation of new round: %@    current round object: %@", [self.roundObject objectForKey:@"roundNumber"], self.roundObject);
        [self sendPushToOpponent]; // send push notification to opponent
        NSLog(@"current user is not the receiver, he's the sender. let him see stats, switch turns / send a push notification and then go to main menu to wait. RECEIVER HAS NOT PLAYED.");
        [self.roundObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred." message:@"Please try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alertView show];
            }
            else {
                [self.roundsRelation addObject:self.roundObject]; // add the new round object to the game's rounds relation
                NSLog(@"round saved successfully. %@", self.roundObject);
                [self.createdGame saveInBackgroundWithBlock:completion]; // save game
            }
        }];
    }
    
}

- (void)getRoundObject:(void (^)(PFObject *round, NSError *error))completion whereRoundNumberIs:(NSNumber *)roundNumber {
    // get the round object with the matching round number
    PFQuery *roundsQuery = [self.roundsRelation query];
    [roundsQuery whereKey:@"roundNumber" equalTo:roundNumber];
    [roundsQuery getFirstObjectInBackgroundWithBlock:completion];
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

- (void)incrementOpponentWins {
    // update the amount of wins the opponent has.
    [PFCloud callFunctionInBackground:@"incrementOpponentWins" withParameters:@{@"userId": self.opponent.objectId} block:^(NSNumber *opponentWins, NSError *error) {
        if (error) {
            NSLog(@"error incrementing opponent's wins.");
        } else {
            NSLog(@"successfully incremented opponent's wins: %@", opponentWins);
        }
    }];
}

- (void)incrementOpponentLosses {
    // update the amount of losses the opponent has.
    [PFCloud callFunctionInBackground:@"incrementOpponentLosses" withParameters:@{@"userId": self.opponent.objectId} block:^(NSNumber *opponentLosses, NSError *error) {
        if (error) {
            NSLog(@"error incrementing opponent's losses.");
        } else {
            NSLog(@"successfully incremented opponent's losses: %@", opponentLosses);
        }
    }];
}

- (void)incrementCurrentUserWins {
    // update the amount of wins the opponent has.
    [PFCloud callFunctionInBackground:@"incrementCurrentUserWins" withParameters:@{@"userId": [PFUser currentUser].objectId} block:^(NSNumber *currentUserWins, NSError *error) {
        if (error) {
            NSLog(@"error incrementing current user's wins.");
        } else {
            NSLog(@"successfully incremented current user's wins: %@", currentUserWins);
        }
    }];
}

- (void)incrementCurrentUserLosses {
    // update the amount of losses the opponent has.

    [PFCloud callFunctionInBackground:@"incrementCurrentUserLosses" withParameters:@{@"userId": [PFUser currentUser].objectId} block:^(NSNumber *currentUserLosses, NSError *error) {
        if (error) {
            NSLog(@"error incrementing current user's losses.");
        } else {
            NSLog(@"successfully incremented current user's losses: %@", currentUserLosses);
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
