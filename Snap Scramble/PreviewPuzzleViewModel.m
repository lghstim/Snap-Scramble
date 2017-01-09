//
//  PreviewPuzzleViewModel.m
//  Snap Scramble
//
//  Created by Tim Gorer on 7/23/16.
//  Copyright © 2016 Tim Gorer. All rights reserved.
//

#import "PreviewPuzzleViewModel.h"

@implementation PreviewPuzzleViewModel

-(id)init {
    self = [super init];
    if (self) {
        // properties get set later
    }
    
    return self;
}


- (PFObject *)setGameKeyParameters:(NSData *)fileData fileType:(NSString *)fileType fileName:(NSString *)fileName {
    PFFile* file; // file
    
    // set all parameters we need for the cloud game object. this is for either a new game or an existing game when the current user has to reply.
    if ([self.createdGame objectForKey:@"receiverPlayed"] == [NSNumber numberWithBool:true] &&   [[self.createdGame objectForKey:@"receiverName"]  isEqualToString:[PFUser currentUser].username]) { // if the RECEIVER has played but the receiver has yet to send back, let him. This code is executed when the current user is replying.
        file = [PFFile fileWithName:fileName data:fileData];
        [self.createdGame setObject:self.puzzleSize forKey:@"puzzleSize"];
        [self.createdGame setObject:file forKey:@"file"];
        [self.createdGame setObject:fileType forKey:@"fileType"];
        [self.createdGame setObject:self.opponent forKey:@"receiver"];
        [self.createdGame setObject:[PFUser currentUser] forKey:@"sender"]; // is this necessary?
        [self.createdGame setObject:[PFUser currentUser].username forKey:@"senderName"]; // receiver becomes sender here
        [self.createdGame setObject:[[PFUser currentUser] objectId] forKey:@"senderID"];
        [self.createdGame setObject:[NSNumber numberWithBool:false] forKey:@"receiverPlayed"]; // set that the receiver has not played
        // set later so that a glitch doesn't happen
        [self.createdGame setObject:@"" forKey:@"receiverID"];
        [self.createdGame setObject:@"" forKey:@"receiverName"];
        [self.createdGame setObject:[NSNumber numberWithInt:0] forKey:@"receiverTime"]; // reset the time
        [self.createdGame setObject:[NSNumber numberWithInt:0] forKey:@"senderTime"]; // reset the time
    }
    
    else if (self.createdGame == nil) { // if the game is a NEWLY created game, current user is the SENDER. This game is executed when the current user creates a new game.
        self.createdGame = [PFObject objectWithClassName:@"Game"];
        [self.createdGame setObject:self.puzzleSize forKey:@"puzzleSize"];
        [self.createdGame setObject:[[PFUser currentUser] objectId] forKey:@"senderID"];
        [self.createdGame setObject:[[PFUser currentUser] username] forKey:@"senderName"];
        [self.createdGame setObject:self.opponent forKey:@"receiver"];
        [self.createdGame setObject:[PFUser currentUser] forKey:@"sender"];
        file = [PFFile fileWithName:fileName data:fileData];
        [self.createdGame setObject:file forKey:@"file"];
        [self.createdGame setObject:fileType forKey:@"fileType"];
        [self.createdGame setObject:[NSNumber numberWithBool:false] forKey:@"receiverPlayed"]; // set that the receiver has not played
       
        // set later so that a glitch doesn't happen
        [self.createdGame setObject:@"" forKey:@"receiverID"];
        [self.createdGame setObject:@"" forKey:@"receiverName"];
    }
    
    self.file = file; // set the file property
    return self.createdGame;
}


// get the current round
/* - (NSNumber*)getRoundNumber {
    self.roundNumber = [self.roundObject objectForKey:@"roundNumber"];
    return self.roundNumber;
}

- (PFObject *)getRoundObject {
    return self.roundObject;
} */

// save the file (photo) before saving the game cloud object
- (void)saveFile:(void (^)(BOOL succeeded, NSError *error))completion {
    [self.file saveInBackgroundWithBlock:completion];
}

// save the game cloud object
- (void)saveCurrentGame:(void (^)(BOOL succeeded, NSError *error))completion {
    [self.createdGame saveInBackgroundWithBlock:completion];
}



@end
