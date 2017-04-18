//
//  FriendsTableViewController.m
//  Snap Scramble
//
//  Created by Tim Gorer on 3/5/16.
//  Copyright © 2016 Tim Gorer. All rights reserved.
//

#import "FriendsTableViewController.h"
#import "Reachability.h"
#import "CreatePuzzleViewController.h"
#import "FriendsViewModel.h"


@interface FriendsTableViewController ()

@property(nonatomic, strong) FriendsViewModel *viewModel;

@end

@implementation FriendsTableViewController

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _viewModel = [[FriendsViewModel alloc] initWithFriendsRelation:[[PFUser currentUser] relationForKey:@"friends"]];
    }
    
    return self;
}

# pragma mark - view methods

- (void)viewDidLoad {
    [super viewDidLoad];
    //[self setNavigationBar];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:false];
    
    self.totalSeconds = [NSNumber numberWithInt:0];
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(incrementTime) userInfo:nil repeats:YES];
    self.friendsRelation = self.viewModel.friendsRelation;
    [KVNProgress showWithStatus:@"Loading friends list..."];
    [self.viewModel retrieveFriends:^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"Error %@ %@", error, [error userInfo]);
            [KVNProgress dismiss];
            [self.timeoutTimer invalidate];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Woops!" message:@"An error occurred. Please try again later." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
            [self.navigationController popViewControllerAnimated:YES];
        }
        
        else {
            self.friends = objects;
            self.mutableFriendsList = [NSMutableArray arrayWithArray:self.friends]; // set mutable list
            [self.tableView reloadData];
            [self.viewModel saveCurrentUser:^(BOOL succeeded, NSError *error) {
                if (error) {
                    NSLog(@"Error %@ %@", error, [error userInfo]);
                }
                
                else {
                    NSLog(@"friends list: %@", self.mutableFriendsList);
                    [self.timeoutTimer invalidate];
                    [KVNProgress dismiss];
                    [self.tableView reloadData];
                }
            }];
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController.navigationBar setHidden:true];
}

- (void)setNavigationBar {
    UINavigationBar *navbar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    navbar.backgroundColor = [self colorWithHexString:@"71C7F0"];
    navbar.barTintColor = [self colorWithHexString:@"71C7F0"];
    UINavigationItem* navItem = [[UINavigationItem alloc] initWithTitle:@"Snap Scramble"];
    [navItem.titleView setFrame:CGRectMake(navItem.titleView.frame.origin.x, navItem.titleView.frame.origin.y + 30, navItem.titleView.frame.size.width, navItem.titleView.frame.size.height)];
    [navbar setItems:@[navItem]];
    [self.view addSubview:navbar];
    [self.view bringSubviewToFront:navbar];
}

# pragma mark - navigation
- (IBAction)addFriendButtonDidPress:(id)sender {
    [self addFriend];
}

- (IBAction)goBackButtonDidPress:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

# pragma mark - game logic

- (void)addFriend {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Search for a user." message:@"Enter the person's username." preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:nil];
    
    [alert addAction: [UIAlertAction actionWithTitle:@"Search" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textField = alert.textFields[0];
        
        if (textField) {
            [KVNProgress showWithStatus:@"Adding friend..."];
            self.totalSeconds = [NSNumber numberWithInt:0];
            self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(incrementTime) userInfo:nil repeats:YES];
        }
        
        NSString *username = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSLog(@"text was %@", textField.text);
        NSString *comparisonUsername = [[PFUser currentUser].username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        // convert string to lowercase
        NSString *lowercaseString = [username lowercaseString]; // get the lowercase username
        
        Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
        NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
        
        if ([username length] == 0) {
            [KVNProgress dismiss];
            [self.timeoutTimer invalidate];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Woops!" message:@"Please enter a username" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        }
        
        
        else if ([username isEqualToString:comparisonUsername]) {
            [KVNProgress dismiss];
            [self.timeoutTimer invalidate];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Woops!" message:@"You cannot play a game with yourself." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        }
        
        else if (networkStatus == NotReachable) {
            [KVNProgress dismiss];
            [self.timeoutTimer invalidate];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Woops!" message:@"Your device appears to not have an internet connection." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        }
        
        // if everything is ok, start searching for the friend
        else {
            [self.viewModel getFriend:username completion:^(PFObject *searchedUser, NSError *error) {
                if (!error) {
                    NSLog(@"trying to add friend: %@", searchedUser);
                    if (searchedUser != nil) { // if the friend exists
                        
                        // if the user isn't already a friend, add him
                        if (![self.viewModel isFriend:searchedUser friendsList:self.mutableFriendsList]) {
                            [self.mutableFriendsList addObject:searchedUser];
                            [self.friendsRelation addObject:searchedUser];
                            [self.viewModel saveCurrentUser:^(BOOL succeeded, NSError *error) {
                                if (!error) {
                                    [self.timeoutTimer invalidate];
                                    [KVNProgress dismiss];
                                    NSLog(@"new friends list: %@", self.mutableFriendsList);
                                    self.mutableFriendsList = [self sortFriendsList];
                                    [self.tableView reloadData];
                                    
                                } else {
                                    NSLog(@"error");
                                }
                            }];
                        }
                        
                        // if the user is already a friend, don't add him
                        else {
                            [KVNProgress dismiss];
                            [self.timeoutTimer invalidate];
                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Woops!" message:@"This user is already on your friends list." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                            [alertView show];
                        }
                    } else { // error
                        [KVNProgress dismiss];
                        [self.timeoutTimer invalidate];
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Woops!" message:@"An error occurred. Please try again later" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                        [alertView show];
                    }
                }
                
                
                // if the user doesn't exist, display a message
                else {
                    [KVNProgress dismiss];
                    [self.timeoutTimer invalidate];
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry!" message:@"This user does not exist." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [alertView show];
                }
            }]; // dismiss progressview if first error or after last save. invalidate timer if first error or after last save. go back a VC if error.
        }
    }]];
    
            
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        NSLog(@"Cancel pressed");
    }]];
    alert.popoverPresentationController.sourceView = self.view;
    [self presentViewController:alert animated:YES
                     completion:nil];
}

- (NSMutableArray*)sortFriendsList {
    NSSortDescriptor *dateDescriptor = [NSSortDescriptor
                                        sortDescriptorWithKey:@"username"
                                        ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:dateDescriptor];
    return [NSMutableArray arrayWithArray:[self.mutableFriendsList sortedArrayUsingDescriptors:sortDescriptors]];
}

# pragma mark - UITableView methods logic

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.mutableFriendsList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    }
    
    UIFont *myFont = [UIFont fontWithName: @"Avenir Next" size: 18.0 ];
    cell.textLabel.font = myFont;
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    cell.detailTextLabel.minimumScaleFactor = 0.5;
    PFUser* friend = [self.mutableFriendsList objectAtIndex:indexPath.row];
    cell.textLabel.text = friend.username;
    
    if ([friend.username isEqualToString:@"tim"]) {
        cell.detailTextLabel.text = @"Snap Scramble founder";
        cell.detailTextLabel.textColor = [UIColor colorWithRed:252.0/255.0 green:194.0/255.0 blue:0 alpha:1.0];
    }
    
    else {
        cell.detailTextLabel.text = @"";
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // set this friend as the opponent.
    self.opponent = [self.mutableFriendsList objectAtIndex:indexPath.row];
    NSLog(@"opponent: %@", self.opponent);
    
    // delegate allows us to transfer opponent's data back to previous view controller for creating puzzle game
    [self.delegate receiveFriendUserData:self.opponent];
    [self.navigationController popViewControllerAnimated:NO];
}

# pragma mark - timer method logic

- (void)incrementTime {
    int value = [self.totalSeconds intValue];
    self.totalSeconds = [NSNumber numberWithInt:value + 1];
    NSLog(@"%@", self.totalSeconds);
    
    // if too much time passed in uploading
    if ([self.totalSeconds intValue] > 20) {
        NSLog(@"timeout error. took longer than 20 seconds");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred." message:@"Please try again later." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        [self.timeoutTimer invalidate];
    }
}

# pragma mark - pass data methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"createPuzzle"]) {
        CreatePuzzleViewController *createPuzzleViewController = (CreatePuzzleViewController *)segue.destinationViewController;
        createPuzzleViewController.opponent = self.opponent;
    }
}

# pragma mark - other methods

// create a hex color
-(UIColor*)colorWithHexString:(NSString*)hex {
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) return [UIColor grayColor];
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    
    if ([cString length] != 6) return  [UIColor grayColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0f];
}


@end
