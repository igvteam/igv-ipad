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
//  FileURLDialogController.m
//  IGV
//
//  Created by Douglass Turner on 2/3/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "FileURLDialogController.h"
#import "FileListItem.h"
#import "Logging.h"
#import "NSString+FileURLAndLocusParsing.h"
#import "GenomeManager.h"
#import "IGVHelpful.h"

@interface FileURLDialogController ()

@property(nonatomic, retain) IBOutlet UITextField *labelTextField;
@property(nonatomic, retain) IBOutlet UITextField *fileURLDialogTextField;
@property(nonatomic, retain) IBOutlet UITextField *bedIndexFileURLDialogTextField;

- (IBAction)cancelWithBarButtonItem:(UIBarButtonItem *)barButtonItem;
- (IBAction)saveWithBarButtonItem:(UIBarButtonItem *)barButtonItem;

- (void)addFileListItemWithFileURLTextField:(UITextField *)fileURLTextField labelTextField:(UITextField *)labelTextField bedIndexFileURLTextField:(UITextField *)bedIndexFileURLTextField;
@end

@implementation FileURLDialogController

@synthesize labelTextField = _labelTextField;
@synthesize fileURLDialogTextField = _fileURLDialogTextField;
@synthesize bedIndexFileURLDialogTextField = _bedIndexFileURLDialogTextField;
@synthesize delegate;

- (void)dealloc {

    self.labelTextField = nil;
    self.fileURLDialogTextField = nil;
    self.delegate = nil;

    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated {
    [self.fileURLDialogTextField becomeFirstResponder];
}

- (void)viewDidUnload {
    self.fileURLDialogTextField = nil;
}

#pragma mark - UITextFieldDelegate Methods

- (void)cancelWithBarButtonItem:(UIBarButtonItem *)barButtonItem {
    
    [self.labelTextField resignFirstResponder];
    [self.fileURLDialogTextField resignFirstResponder];
    
    [self.delegate fileURLDialogController:self addFileListItem:nil];

}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    return YES;
}

- (void)saveWithBarButtonItem:(UIBarButtonItem *)barButtonItem {
    [self addFileListItemWithFileURLTextField:self.fileURLDialogTextField
                               labelTextField:self.labelTextField
                     bedIndexFileURLTextField:nil];

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    [self addFileListItemWithFileURLTextField:self.fileURLDialogTextField
                               labelTextField:self.labelTextField
                     bedIndexFileURLTextField:nil];

    return YES;
}

- (void)addFileListItemWithFileURLTextField:(UITextField *)fileURLTextField
                             labelTextField:(UITextField *)labelTextField
                   bedIndexFileURLTextField:(UITextField *)bedIndexFileURLTextField {

    BOOL fileURLIsAbsent = (nil == fileURLTextField.text || [@"" isEqualToString:fileURLTextField.text]);
    BOOL bedFileURLIsAbsent = (nil == bedIndexFileURLTextField.text || [@"" isEqualToString:bedIndexFileURLTextField.text]);

    if (fileURLIsAbsent) {
        [self.delegate fileURLDialogController:self addFileListItem:nil];
        return;
    }

    NSString *fileURLPath = [fileURLTextField.text removeHeadTailWhitespace];

    NSString *blurb = nil;
    if (![IGVHelpful isUsablePath:fileURLPath blurb:&blurb]) {

        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:blurb
                                                            delegate:self
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil] autorelease];

        [alertView show];

        return;
    }

    NSString *label = (nil == labelTextField.text) ? [FileListItem defaultLabelWithFileURLPath:fileURLPath] : labelTextField.text;

    FileListItem *fileListItem = [[[FileListItem alloc] initWithFileURLPath:fileURLPath
                                                                      label:label
                                                                     genome:[GenomeManager sharedGenomeManager].currentGenomeName] autorelease];

    [self.labelTextField resignFirstResponder];
    [self.fileURLDialogTextField resignFirstResponder];

    [self.delegate fileURLDialogController:self addFileListItem:fileListItem];

}

- (void)alertViewCancel:(UIAlertView *)alertView {

//    ALog(@"%@. Cancelled.", [self class]);
}

#pragma mark - Interface Orientation Management

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - Nib Name

- (NSString *)nibName {
    return NSStringFromClass([self class]);
}

@end
