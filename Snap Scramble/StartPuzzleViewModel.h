//
//  StartPuzzleViewModel.h
//  Snap Scramble
//
//  Created by Tim Gorer on 1/10/17.
//  Copyright © 2017 Tim Gorer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface StartPuzzleViewModel : NSObject

@property (nonatomic, strong) PFRelation* roundsRelation;

- (void)getRoundObject:(void (^)(PFObject *round, NSError *error))completion whereRoundNumberIs:(NSNumber *)roundNumber;

@end
