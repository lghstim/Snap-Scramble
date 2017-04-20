//
//  SignupViewController.m
//  Snap Scramble
//
//  Created by Tim Gorer on 7/20/15.
//  Copyright (c) 2015 Tim Gorer. All rights reserved.
//

#import "SignupViewController.h"
#import "SignupViewModel.h"

@interface SignupViewController ()

@property(nonatomic, strong) SignupViewModel *viewModel;

@end

@implementation SignupViewController

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _viewModel = [[SignupViewModel alloc] init];
    }
    
    return self;
}

# pragma mark - views

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    self.navigationItem.hidesBackButton = YES;
    [self.navigationItem.backBarButtonItem setTitle:@""];
    self.usernameField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.createUsernameField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.reenterPasswordField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.emailField.autocorrectionType = UITextAutocorrectionTypeNo;
    [self.passwordField setDelegate:self];
    [self.usernameField setDelegate:self];
    [self.reenterPasswordField setDelegate:self];
    [self.emailField setDelegate:self];
    [self.createUsernameField setDelegate:self];
    self.legalButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.legalButton.titleLabel.minimumScaleFactor = 0.5;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.navigationController.navigationBar setHidden:true];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setHidden:false];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

# pragma mark - navigation

- (IBAction)signupButtonDidPress:(id)sender {
    [self signUpUser];
}

- (IBAction)signupWithFacebookButtonDidPress:(id)sender {
    [self signUpUserWithFacebook];
}

- (IBAction)finishButtonDidPress:(id)sender {
    [self signUpUser];
}

# pragma mark - keyboard methods logic

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    if (theTextField == self.usernameField) {
        [self.usernameField resignFirstResponder];
        [self.passwordField becomeFirstResponder];
    }
    
    if (theTextField == self.passwordField) {
        [self.passwordField resignFirstResponder];
        [self.reenterPasswordField becomeFirstResponder];
    }
    
    else if (theTextField == self.reenterPasswordField) {
        [self.reenterPasswordField resignFirstResponder];
        [self.emailField becomeFirstResponder];
    }
    
    else if (theTextField == self.emailField) {
        [self.emailField resignFirstResponder];
    }
    
    else if (theTextField == self.createUsernameField) {
        [self.createUsernameField resignFirstResponder];
    }
    
    return YES;
}


-(void)dismissKeyboard {
    if ([self.passwordField isFirstResponder]) {
        [self.passwordField resignFirstResponder];
    }
    
    else if ([self.usernameField isFirstResponder]) {
        [self.usernameField resignFirstResponder];
    }
    
    else if ([self.reenterPasswordField isFirstResponder]) {
        [self.reenterPasswordField resignFirstResponder];
    }
    
    else if ([self.emailField isFirstResponder]) {
        [self.emailField resignFirstResponder];
    }
}

# pragma mark - signup methods logic

- (BOOL)usernameTaken:(NSString *)username{
    PFQuery *query = [PFUser query];
    [query whereKey:@"username" equalTo:username];
    NSArray *objects = [query findObjects];

    if ([objects count] == 0) {
        return FALSE;
    } else {
        return TRUE;
    }
}

- (void)signUpUserWithFacebook {
    [PFFacebookUtils logInInBackgroundWithReadPermissions:@[@"email", @"user_friends"] block:^(PFUser *user, NSError *error) {
        if (!user) {
            NSLog(@"Uh oh. The user cancelled the Facebook login.");
        } else if (user.isNew) {
            NSLog(@"User signed up and logged in through Facebook!");
            [self performSegueWithIdentifier:@"createUsername" sender:self];
        } else { // user isn't new, take him to root vc
            NSLog(@"User logged in through Facebook!");
            [self.navigationController popToRootViewControllerAnimated:NO];
        }
    }];
}

- (void)signUpUser {
    NSString *username = [self.createUsernameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    username = [username lowercaseString]; // make all strings lowercase
    // white space check variable
    NSRange whiteSpaceRange = [username rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // check if username has only alphanumeric characters
    NSCharacterSet *alphaSet = [NSCharacterSet alphanumericCharacterSet];
    BOOL alphaNumericValid = [[username stringByTrimmingCharactersInSet:alphaSet] isEqualToString:@""];
    
    
    // checks for if the sign up information is valid start here
    if ([username length] == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"Please enter a valid username." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
    }
    
    // alphanumeric check
    else if (alphaNumericValid == false) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"Password must contain only letters and numbers." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
        [alertView show];
    }
    
    else if ([username length] > 10) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"Username is too long. Please keep it below 10 characters." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
        [alertView show];
    }
    
    else if ([username length] < 3) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"Username is too short. Please keep it between 3 and 10 characters." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
        [alertView show];
    }
    
    // check for whitespaces
    else if (whiteSpaceRange.location != NSNotFound) {
        NSLog(@"Found whitespace");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"Username has a space in it." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
        [alertView show];
    }
    
    else { // good
        // initiate timer for timeout
        self.totalSeconds = [NSNumber numberWithInt:0];
        self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(incrementTime) userInfo:nil repeats:YES];
        if (![self usernameTaken:username]) {
            [KVNProgress showWithStatus:@"Signing up..."]; // UI
            [[PFUser currentUser] setUsername:username];
            [self.viewModel saveCurrentUser:^(BOOL succeeded, NSError *error) {
                if (error) {
                    NSLog(@"Error %@ %@", error, [error userInfo]);
                    [KVNProgress dismiss];
                    [self.timeoutTimer invalidate];
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"An error occurred." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [alertView show];
                }
                
                else {
                    [self.navigationController popToRootViewControllerAnimated:NO];
                    [self.timeoutTimer invalidate];
                    [KVNProgress dismiss];
                }
            }];
        } else {
            [self.timeoutTimer invalidate];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"This username is already taken." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        }
    }
}

# pragma mark - timer methods logic

- (void)incrementTime {
    int value = [self.totalSeconds intValue];
    self.totalSeconds = [NSNumber numberWithInt:value + 1];
    NSLog(@"%@", self.totalSeconds);
    
    // if too much time passed in uploading
    if ([self.totalSeconds intValue] > 20) {
        NSLog(@"timeout error. took longer than 20 seconds");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"A server error occurred." message:@"Please play again later." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
        [KVNProgress dismiss];
        [self.timeoutTimer invalidate];
    }
    
}

- (void)dealloc {
    self.timeoutTimer = nil;
}



@end
