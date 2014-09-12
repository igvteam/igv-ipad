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
//  GenericPopupTrackMenuController.m
//  IGV
//
//  Created by turner on 5/12/14.
//
//

#import "GenericPopupTrackMenuController.h"
#import "TrackDelegate.h"
#import "TrackDataRangeController.h"
#import "FeatureTrackView.h"
#import "DataScale.h"
#import "Logging.h"
#import "UIApplication+IGVApplication.h"
#import "RootContentController.h"
#import "TrackContainerScrollView.h"
#import "LMResource.h"
#import "TrackLayoutController.h"
#import "RenameTrackController.h"
#import "PListPersistence.h"

@implementation GenericPopupTrackMenuController

@synthesize trackDelegate = _trackDelegate;

- (void)dealloc {

    self.trackDelegate = nil;
    [super dealloc];
}

#pragma mark - UITableViewDataSource Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

#pragma mark - UITableViewDataSource Delegate Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

    [self presentTableViewCell:cell indexPath:indexPath];
    return cell;
}

- (void)presentTableViewCell:(UITableViewCell *)tableViewCell indexPath:(NSIndexPath *)indexPath {

    if (0 == indexPath.section && 0 == indexPath.row) {

        RootContentController *rootContentController = [UIApplication sharedRootContentController];
        UILabel *label = [tableViewCell.contentView.subviews objectAtIndex:0];
        label.text = [NSString stringWithFormat:@"%@ Track Labels", rootContentController.trackContainerScrollView.trackLabelsAreHidden ? @"Show" : @"Hide"];
    }

}

#pragma mark - UITableViewDelegate Delegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [self configureTableViewCell:[self tableView:self.tableView cellForRowAtIndexPath:indexPath]
                       indexPath:indexPath];

}

- (void)configureTableViewCell:(UITableViewCell *)tableViewCell indexPath:(NSIndexPath *)indexPath {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    TrackView *trackView = self.trackDelegate.track;

    if (0 == indexPath.section) {

        switch (indexPath.row) {

            case 0: {
                [rootContentController.trackContainerScrollView toggleTrackLabels];
            }
                break;

            case 1: {
                return;
            }

            default: {
                // nuthin
            }
        }

    }

    if (1 == indexPath.section) {

        switch (indexPath.row) {

            case 0: {
                trackView.resource.enabled = NO;
                [rootContentController discardTrackWithResource:trackView.resource];
            }
                break;

            case 1: {
                return;
            }

            default: {
                // nuthin
            }
        }

    }

    [rootContentController.trackMenuPopoverController dismissPopoverAnimated:YES];
    rootContentController.trackMenuPopoverController = nil;

}

#pragma mark - UIStoryboard methods

- (IBAction)unwindControllerWithSeque:(UIStoryboardSegue *)segue {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    [rootContentController.trackMenuPopoverController dismissPopoverAnimated:YES];
    rootContentController.trackMenuPopoverController = nil;

    if ([@"UnwindRenameControllerWithCancel" isEqualToString:segue.identifier]) {
        return;
    }

    if ([@"UnwindRenameControllerWithDone" isEqualToString:segue.identifier]) {

        RenameTrackController *renameTrackController = segue.sourceViewController;

        if (nil == renameTrackController.renameTrackTextField.text || [renameTrackController.renameTrackTextField.text isEqualToString:@""]) {
            return;
        }

        self.trackDelegate.track.resource.name   = renameTrackController.renameTrackTextField.text;
        self.trackDelegate.track.trackLabel.text = renameTrackController.renameTrackTextField.text;
        [self.trackDelegate.track.trackLabel sizeToFit];
        [self.trackDelegate.track.trackLabel setNeedsDisplay];
        return;
    }

    if ([@"UnwindTrackLayoutControllerWithCancel" isEqualToString:segue.identifier]) {
        return;
    }

    if ([@"UnwindTrackLayoutControllerWithDone" isEqualToString:segue.identifier]) {

        TrackLayoutController *trackLayoutController = segue.sourceViewController;
        [rootContentController.trackContainerScrollView layoutTracksWithOutputOrder:trackLayoutController.outputOrder inputOrder:trackLayoutController.inputOrder];
        return;
    }


}

@end
