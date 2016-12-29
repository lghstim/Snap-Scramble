//
//  GameViewModel.m
//  Snap Scramble
//
//  Created by Tim Gorer on 8/2/16.
//  Copyright © 2016 Tim Gorer. All rights reserved.
//

#import "GameViewModel.h"

@implementation GameViewModel

-(id)initWithOpponent:(PFUser *)opponent andGame:(PFObject *)createdGame {
    self = [super init];
    if (self) {
        self.opponent = opponent;
        self.createdGame = createdGame;
    }
    
    return self;
}

// change the turn - make the receiver the opponent
- (void)switchTurns {
    [self.createdGame setObject:self.opponent.objectId forKey:@"receiverID"];
    [self.createdGame setObject:self.opponent.username forKey:@"receiverName"];
}

// save the game cloud object
- (void)saveCurrentGame:(void (^)(BOOL succeeded, NSError *error))completion {
    [self.createdGame saveInBackgroundWithBlock:completion];
}

- (void)sendNotificationToOpponent {
    PFUser *currentUser = [PFUser currentUser];
    PFQuery *innerQuery = [PFUser query];
    
    NSLog(@"You sent a notification to: objectID: %@", self.opponent.objectId);
    [innerQuery whereKey:@"objectId" equalTo:self.opponent.objectId];
    
    // Build the actual push notification target query
    PFQuery *query = [PFInstallation query];
    
    // only return Installations that belong to a User that
    // matches the innerQuery
    [query whereKey:@"User" matchesQuery:innerQuery];
    
    // Send the notification.
    PFPush *push = [[PFPush alloc] init];
    [push setQuery:query];
    
    NSString *message = [NSString stringWithFormat:@"%@ has sent you a puzzle!", currentUser.username];
    [push setMessage:message];
    
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                          message, @"alert",
                          @"Increment", @"badge",
                          @"cheering.caf", @"sound",
                          nil];
    [push setData:data];
    [push sendPushInBackground];
}



@end
