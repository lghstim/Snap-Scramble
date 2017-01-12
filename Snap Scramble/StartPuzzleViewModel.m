//
//  StartPuzzleViewModel.m
//  Snap Scramble
//
//  Created by Tim Gorer on 1/10/17.
//  Copyright © 2017 Tim Gorer. All rights reserved.
//

#import "StartPuzzleViewModel.h"

@implementation StartPuzzleViewModel

- (void)getRoundObject:(void (^)(PFObject *round, NSError *error))completion whereRoundNumberIs:(NSNumber *)roundNumber {
    // get the round object with the matching round number
    PFQuery *roundsQuery = [self.roundsRelation query];
    [roundsQuery whereKey:@"roundNumber" equalTo:roundNumber];
    [roundsQuery getFirstObjectInBackgroundWithBlock:completion];
}

@end
