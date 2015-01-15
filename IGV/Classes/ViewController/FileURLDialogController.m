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
#import "TrackDelegate.h"

@interface FileURLDialogController ()

@property(nonatomic, retain) IBOutlet UITextField *labelTextField;
@property(nonatomic, retain) IBOutlet UITextField *filePathDialogTextField;
@property(nonatomic, retain) IBOutlet UITextField *indexPathDialogTextField;
@property(nonatomic, retain) IBOutlet UISwitch *presentIndexPathDialog;
@property(nonatomic) CGRect srcFrame;
@property(nonatomic) CGRect dstFrame;

- (IBAction)cancelWithBarButtonItem:(UIBarButtonItem *)barButtonItem;
- (IBAction)saveWithBarButtonItem:(UIBarButtonItem *)barButtonItem;
- (IBAction)presentIndexPathDialogHandler:(UISwitch *)presentIndexPathDialog;

- (void)addFileListItemWithFilePathTextField:(UITextField *)filePathTextField labelTextField:(UITextField *)labelTextField indexPathTextField:(UITextField *)indexPathTextField;
@end

@implementation FileURLDialogController

@synthesize labelTextField = _labelTextField;
@synthesize filePathDialogTextField = _filePathDialogTextField;
@synthesize indexPathDialogTextField = _indexPathDialogTextField;
@synthesize presentIndexPathDialog = _presentIndexPathDialog;
@synthesize srcFrame = _srcFrame;
@synthesize dstFrame = _dstFrame;
@synthesize delegate;

- (void)dealloc {

    self.filePathDialogTextField = nil;
    self.indexPathDialogTextField = nil;
    self.presentIndexPathDialog = nil;
    self.labelTextField = nil;
    self.delegate = nil;

    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {

    self.dstFrame = self.srcFrame = self.labelTextField.frame;
    self.dstFrame = CGRectMake(self.dstFrame.origin.x, self.dstFrame.origin.y + 125, self.dstFrame.size.width, self.dstFrame.size.height);
}

- (void)viewDidAppear:(BOOL)animated {
    [self.filePathDialogTextField becomeFirstResponder];
}

- (void)viewDidUnload {
    self.filePathDialogTextField = nil;
    self.indexPathDialogTextField = nil;
    self.labelTextField = nil;
}

#pragma mark - UITextFieldDelegate Methods

- (void)cancelWithBarButtonItem:(UIBarButtonItem *)barButtonItem {
    
    [self.labelTextField resignFirstResponder];
    [self.filePathDialogTextField resignFirstResponder];
    [self.indexPathDialogTextField resignFirstResponder];

    [self.delegate fileURLDialogController:self addFileListItem:nil];

}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    return YES;
}

- (void)saveWithBarButtonItem:(UIBarButtonItem *)barButtonItem {
    [self addFileListItemWithFilePathTextField:self.filePathDialogTextField
                                labelTextField:self.labelTextField
                            indexPathTextField:self.indexPathDialogTextField];

}

- (IBAction)presentIndexPathDialogHandler:(UISwitch *)presentIndexPathDialog {

    ALog(@"%@ %@", [presentIndexPathDialog class], (YES == presentIndexPathDialog.on) ? @"On" : @"Off");

    CGRect targetFrame = (presentIndexPathDialog.on) ? self.dstFrame : self.srcFrame;

    [UIView animateWithDuration:kSquishAnimationDuration
                          delay:kSquishAnimationDelay
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{

                         self.labelTextField.frame = targetFrame;
                     }
                     completion:^(BOOL finished){

                         self.indexPathDialogTextField.hidden = !(presentIndexPathDialog.on);
                     }];

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    [self addFileListItemWithFilePathTextField:self.filePathDialogTextField
                                labelTextField:self.labelTextField
                            indexPathTextField:self.indexPathDialogTextField];

    return YES;
}

- (void)addFileListItemWithFilePathTextField:(UITextField *)filePathTextField
                              labelTextField:(UITextField *)labelTextField
                          indexPathTextField:(UITextField *)indexPathTextField {

    BOOL filePathIsAbsent  = (nil ==  filePathTextField.text || [@"" isEqualToString: filePathTextField.text]);
    BOOL indexPathIsAbsent = (nil == indexPathTextField.text || [@"" isEqualToString:indexPathTextField.text]);

    if (filePathIsAbsent) {
        [self.delegate fileURLDialogController:self addFileListItem:nil];
        return;
    }

    NSString *filePath = [filePathTextField.text removeHeadTailWhitespace];

    NSString *blurb = nil;
    if (![IGVHelpful isUsablePath:filePath blurb:&blurb]) {

        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:blurb
                                                            delegate:self
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil] autorelease];

        [alertView show];

        return;
    }

    NSString *indexPath = nil;
    if (!indexPathIsAbsent) {

        indexPath = [indexPathTextField.text removeHeadTailWhitespace];

        if (![IGVHelpful isUsableIndexPath:indexPathTextField.text blurb:&blurb filePath:filePath]) {

            UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Error"
                                                                 message:blurb
                                                                delegate:self
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil] autorelease];

            [alertView show];

            return;
        }

    }

    NSString *label = (nil == labelTextField.text) ? [FileListItem defaultLabelWithFilePath:filePath] : labelTextField.text;

    FileListItem *fileListItem = [[[FileListItem alloc] initWithFilePath:filePath
                                                                   label:label
                                                                  genome:[GenomeManager sharedGenomeManager].currentGenomeName
                                                               indexPath:indexPath] autorelease];

    [self.labelTextField resignFirstResponder];
    [self.filePathDialogTextField resignFirstResponder];
    [self.indexPathDialogTextField resignFirstResponder];

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
