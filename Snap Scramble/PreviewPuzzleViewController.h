//
//  PreviewPuzzleViewController.h
//  Snap Scramble
//
//  Created by Tim Gorer on 7/20/15.
//  Copyright (c) 2015 Tim Gorer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <KVNProgress/KVNProgress.h>
#import "RMPickerViewController.h"

@interface PreviewPuzzleViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) PFObject* createdGame;
@property (nonatomic, strong) UIImageView* imageView;
@property (nonatomic, strong) PFUser* opponent;
@property (nonatomic, strong) UIImage* previewImage;
@property (nonatomic, strong) UIImage* originalImage;
@property (nonatomic, strong) UIImage* gameImage;
@property (nonatomic, strong) PFUser* currentUser;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (strong, nonatomic) UIButton *selectPuzzleSizeButton;
@property (nonatomic, strong) NSArray *puzzleSizes;
@property (nonatomic, strong) NSString *puzzleSize;
@property (nonatomic, strong) NSTimer *timeoutTimer;
@property (nonatomic, strong) NSTimer *savePhotoTimer;
@property (nonatomic, strong) NSNumber* totalSeconds;
@property (nonatomic, strong) NSNumber* totalSecondsSavePhotoTimer;
@property (nonatomic, strong) PFObject* roundObject;





@end
