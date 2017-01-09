//
//  GameOverViewModel.h
//  Snap Scramble
//
//  Created by Tim Gorer on 8/4/16.
//  Copyright © 2016 Tim Gorer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface GameOverViewModel : NSObject

@property (nonatomic, strong) NSNumber* currentUserTotalSeconds;
@property (nonatomic, strong) PFObject* createdGame;
@property (nonatomic, strong) PFUser* opponent;
@property (nonatomic, strong) PFObject* roundObject;
@property (nonatomic, strong) PFRelation* roundsRelation;


- (void)updateGame;
- (void)retrieveRounds:(void (^)(NSArray *objects, NSError *error))completion;
- (void)switchTurns;
- (void)saveCurrentGame:(void (^)(BOOL succeeded, NSError *error))completion;
- (void)saveCurrentUser:(void (^)(BOOL succeeded, NSError *error))completion;
- (void)sendPushToOpponent;
- (void)incrementWins;
- (void)incrementLosses;


  


@end
