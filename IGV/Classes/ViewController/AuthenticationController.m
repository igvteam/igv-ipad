// 
// The MIT License (MIT)
// 
// 
// Copyright (c) 2014 Broad Institute
// 
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//


//
//  AuthenticationController.m
//  IGV
//
//  Created by Douglass Turner on 5/3/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "AuthenticationController.h"
#import "Logging.h"

@interface AuthenticationController ()

@end

@implementation AuthenticationController

@synthesize usernameTextField;
@synthesize passwordTextField;
@synthesize challenge;
@synthesize delegate;

- (void)dealloc {

    self.usernameTextField = nil;
    self.passwordTextField = nil;
    self.challenge = nil;
    self.delegate = nil;

    [super dealloc];
}

#pragma mark - UITextFieldDelegate Methods

- (void)cancelWithBarButtonItem:(UIBarButtonItem *)aBarButtonItem {

    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];

    [self.delegate authenticationController:self username:nil password:nil];
}

- (IBAction)doneWithBarButtonItem:(UIBarButtonItem *)aBarButtonItem {

    [self authenticateWithUserNameTextField:self.usernameTextField passwordTextField:self.passwordTextField];

}

- (BOOL)textFieldShouldClear:(UITextField *)textField {

    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    [self authenticateWithUserNameTextField:self.usernameTextField passwordTextField:self.passwordTextField];

    return YES;
}

- (void)authenticateWithUserNameTextField:(UITextField *)aUserNameTextField passwordTextField:(UITextField *)aPasswordTextField {
    ALog(@"authenticateWithUserNameTextField %@ %@", aUserNameTextField.text, aPasswordTextField.text);
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];

    [self.delegate authenticationController:self username:aUserNameTextField.text password:aPasswordTextField.text];

}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {

    [self.usernameTextField becomeFirstResponder];
    self.usernameTextField.text = @"";
    self.passwordTextField.text = @"";
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (NSString *)nibName {

    return NSStringFromClass([self class]);
}

@end
