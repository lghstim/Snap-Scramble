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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    self.navigationItem.hidesBackButton = YES;
    [self.navigationItem.backBarButtonItem setTitle:@""];
    self.usernameField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.reenterPasswordField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.emailField.autocorrectionType = UITextAutocorrectionTypeNo;
    [self.passwordField setDelegate:self];
    [self.usernameField setDelegate:self];
    [self.reenterPasswordField setDelegate:self];
    [self.emailField setDelegate:self];
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
    
    return YES;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */


- (IBAction)signupButtonDidPress:(id)sender {
    NSString *username = [self.usernameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    username = [username lowercaseString]; // make all strings lowercase
    NSString *password = [self.passwordField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *reenteredPassword = [self.reenterPasswordField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *email = [self.emailField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // white space check variable
    NSRange whiteSpaceRange = [username rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    
    
    // convert string to lowercase
    NSString *lowercaseString = [username lowercaseString]; // get the lowercase username
    
    // check if username has only alphanumeric characters
    NSCharacterSet *alphaSet = [NSCharacterSet alphanumericCharacterSet];
    BOOL alphaNumericValid = [[username stringByTrimmingCharactersInSet:alphaSet] isEqualToString:@""];
  
    
    // checks for if the sign up information is valid start here
    if ([username length] == 0 || [password length] == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"Please enter a valid username and password." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
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

    
    else if (![reenteredPassword isEqualToString:password]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"Make sure your you enter your password correctly both times." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
        [alertView show];
    }
    
    else if (![email containsString:@"@"]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"Please enter a valid email." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
        [alertView show];
    }
    
    else {
        // initiate timer for timeout
        self.totalSeconds = [NSNumber numberWithInt:0];
        self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(incrementTime) userInfo:nil repeats:YES];
        
        
        [KVNProgress showWithStatus:@"Signing up..."]; // UI
        [self.viewModel signUpUser:username password:password email:email completion:^(BOOL succeeded, NSError *error) {
            if (error) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry" message:[error.userInfo objectForKey:@"error"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alertView show];
                [self.timeoutTimer invalidate];
                [KVNProgress dismiss];
            }
            
            else {
                [self.timeoutTimer invalidate];
                [self.navigationController popToRootViewControllerAnimated:YES]; // go to the main menu
                NSLog(@"User %@ signed up.", [PFUser currentUser]);
                [KVNProgress dismiss];
                self.signupView.animation = @"fall";
                [self.signupView animate];
            }
        }];
    }
}

- (IBAction)signupWithFacebookButtonDidPress:(id)sender {
    [PFFacebookUtils logInInBackgroundWithReadPermissions:@[@"email", @"user_friends"] block:^(PFUser *user, NSError *error) {
        if (!user) {
            NSLog(@"Uh oh. The user cancelled the Facebook login.");
        } else if (user.isNew) {
            NSLog(@"User signed up and logged in through Facebook!");
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else {
            NSLog(@"User logged in through Facebook!");
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }];
}


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



@end
