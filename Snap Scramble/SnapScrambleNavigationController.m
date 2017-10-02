//
//  SnapScrambleNavigationController.m
//  Snap Scramble
//
//  Created by Tim Gorer on 7/14/17.
//  Copyright © 2017 Tim Gorer. All rights reserved.
//

#import "SnapScrambleNavigationController.h"

@interface SnapScrambleNavigationController ()

@end

@implementation SnapScrambleNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationBar setTranslucent:NO];
    [self.navigationBar setBarTintColor:[UIColor colorWithRed:11.0/255 green:150.0/255 blue:246.0/255 alpha:1]];
    [self.navigationBar setTintColor:[UIColor whiteColor]];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationBar.bounds.size.height - 2, self.navigationBar.bounds.size.width, 2)];
    lineView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    lineView.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.2];
    [self.navigationBar addSubview:lineView];
    [self.navigationBar bringSubviewToFront:lineView];
}


@end
