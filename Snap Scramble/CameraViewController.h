//
//  CameraViewController.h
//  Snap Scramble
//
//  Created by Tim Gorer on 7/23/16.
//  Copyright © 2016 Tim Gorer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LLSimpleCamera.h"
#import <Parse/Parse.h>
#import "JPSVolumeButtonHandler.h"
#import "Snap_Scramble-Swift.h"


@interface CameraViewController : UIViewController

@property (nonatomic, strong) UIImage* cameraImage; // preview image
@property (nonatomic, strong) UIImage* originalImage;
@property (nonatomic, strong) PFObject* createdGame;
@property (nonatomic, strong) PFUser* opponent;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) DesignableButton *bottomButton;
@property (nonatomic, strong) DesignableButton *topButton;
@property (nonatomic, strong) UIImage *downArrow;
@property (nonatomic, strong) UIImage *topArrow;
@property (nonatomic, strong) PFObject* roundObject;
@property (nonatomic, strong) JPSVolumeButtonHandler* volumeButtonHandler;

- (void)showLeftVC;
- (void)deallocate;






@end
