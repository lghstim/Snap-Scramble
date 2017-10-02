//
//  FriendsTableViewCell.h
//  Snap Scramble
//
//  Created by Tim Gorer on 4/20/17.
//  Copyright © 2017 Tim Gorer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FriendsTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *selectionImage;


@end
