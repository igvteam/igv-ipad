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
//  SessionSaveController.m
//  IGV
//
//  Created by turner on 4/8/14.
//
//

#import "SessionSaveController.h"

@implementation SessionSaveController

@synthesize saveSessionTextField = _saveSessionTextField;
@synthesize currentSessionName = _currentSessionName;

- (void)dealloc {

    self.currentSessionName = nil;
    self.saveSessionTextField = nil;

    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {

    self.saveSessionTextField.text = self.currentSessionName;
    [self.saveSessionTextField becomeFirstResponder];

}

#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    [self performSegueWithIdentifier:@"UnwindSaveSessionControllerWithDone" sender:self];
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

}

@end
