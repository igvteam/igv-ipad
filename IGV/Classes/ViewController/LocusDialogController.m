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
//  LocusDialogController.m
//  IGV
//
//  Created by Douglass Turner on 2/3/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "LocusDialogController.h"
#import "LocusListItem.h"
#import "Logging.h"
#import "RootContentController.h"
#import "GenomeManager.h"
#import "IGVContext.h"

@interface LocusDialogController ()
- (void)addLocusListItemWithLocusTextField:(UITextField *)aLocusTextField labelTextField:(UITextField *)aLabelTextField;
@end

@implementation LocusDialogController

@synthesize labelTextField;
@synthesize locusDialogTextField;
@synthesize delegate;

- (void)dealloc {

    self.labelTextField = nil;
    self.locusDialogTextField = nil;
    self.delegate = nil;

    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {

    self.locusDialogTextField.text = [[IGVContext sharedIGVContext] currentLocus];
    [self.locusDialogTextField becomeFirstResponder];

}

- (void)viewDidUnload {
    
    self.locusDialogTextField = nil;

    [super viewDidUnload];
}

#pragma mark - UITextFieldDelegate Methods

- (void)cancelWithBarButtonItem:(UIBarButtonItem *)aBarButtonItem {

    [self.labelTextField resignFirstResponder];
    [self.locusDialogTextField resignFirstResponder];

    [self.delegate locusDialogController:self addLocusListItem:nil];
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    return YES;
}

- (void)saveWithBarButtonItem:(UIBarButtonItem *)aBarButtonItem {
    
    [self addLocusListItemWithLocusTextField:self.locusDialogTextField labelTextField:self.labelTextField];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [self addLocusListItemWithLocusTextField:self.locusDialogTextField labelTextField:self.labelTextField];
    
    return YES;
}

- (void)addLocusListItemWithLocusTextField:(UITextField *)aLocusTextField labelTextField:(UITextField *)aLabelTextField {

    NSString *string = [aLocusTextField.text removeHeadTailWhitespace];

    LocusListFormat locusFormat = [string format];
    
    if (LocusListFormatInvalid == locusFormat) {

        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:[NSString stringWithFormat:@"Invalid locus entered %@", string]
                                                            delegate:self cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil] autorelease];
        [alertView show];
 
        return;
    }
    
    NSString *_label = (nil == aLabelTextField.text) ? @"" : aLabelTextField.text;
    LocusListItem *locusListItem = [[[LocusListItem alloc] initWithLocus:string
                                                                   label:_label
                                                         locusListFormat:locusFormat
                                                              genomeName:[GenomeManager sharedGenomeManager].currentGenomeName] autorelease];

    [self.labelTextField resignFirstResponder];
    [self.locusDialogTextField resignFirstResponder];

    [self.delegate locusDialogController:self addLocusListItem:locusListItem];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {

    [self.locusDialogTextField becomeFirstResponder];
//    self.locusDialogTextField.text = @"";

}

#pragma mark - Interface Orientation Management

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - Nib Name

- (NSString *)nibName {
    return @"LocusDialogController";
}

@end
