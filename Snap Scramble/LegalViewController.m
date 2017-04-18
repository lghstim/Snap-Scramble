//
//  LegalViewController.m
//  Snap Scramble
//
//  Created by Tim Gorer on 4/5/16.
//  Copyright © 2016 Tim Gorer. All rights reserved.
//

#import "LegalViewController.h"

@interface LegalViewController ()

@end

@implementation LegalViewController

# pragma mark - view methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSURL *legalUrl = [[NSURL alloc] initWithString:@"http://www.bit.ly/22ajbo7"];
    [self.legalWebView loadRequest:[[NSURLRequest alloc] initWithURL:legalUrl]];
}

@end
