//
//  GameViewController.h
//  Snap Scramble
//
//  Created by Tim Gorer on 7/20/15.
//  Copyright (c) 2015 Tim Gorer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TargetView.h"
#import "PieceView.h"
#import <Parse/Parse.h>
#import "GameOverViewController.h"
#import "Snap_Scramble-Swift.h"
#import "StartPuzzleViewController.h"
#import "GameObject.h"
#import "PuzzleObject.h"
#import "GameViewModel.h"
#import "PuzzleView.h"
@import AssetsLibrary;
#import <Masonry/Masonry.h>
#import <jot/jot.h>
#import "JotViewController.h"

@interface GameViewController : UIViewController

@property (strong, nonatomic) id<StartVCDelegate> delegate;
@property (strong, nonatomic) IBOutlet UIButton *statsButton;
@property (strong, nonatomic) IBOutlet UIButton *replyButton;
@property (strong, nonatomic) IBOutlet UIButton *replyLaterButton;
@property (strong, nonatomic) IBOutlet UIButton *deleteButton;
@property (strong, nonatomic) IBOutlet UIButton *mainMenuButton;
@property (nonatomic, strong) PFUser *opponent;
@property (nonatomic, strong) PFObject *createdGame;
@property (nonatomic, strong) GameObject *game;
@property (nonatomic, strong) UIImage *puzzleImage;
@property (nonatomic, strong) GameViewModel *viewModel;
@property (nonatomic, strong) PFObject* roundObject;
@property (nonatomic, strong) PuzzleObject* puzzle;
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) NSTimer *savePhotoTimer;
@property (nonatomic, strong) NSNumber* totalSecondsSavePhotoTimer;




- (void)hideShowStatsButtonUI;
- (void)hideReplyButtonUI;
- (void)hideMainMenuUI;
- (void)updateToReplyButtonUI;
- (void)updateToMainMenuButtonUI;
- (void)deallocGameProperties;

@end
