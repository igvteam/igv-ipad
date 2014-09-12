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
//  BAMSEGPopupTrackMenuController.m
//  IGV
//
//  Created by turner on 5/12/14.
//
//

#import "BAMSEGPopupTrackMenuController.h"
#import "TrackDelegate.h"
#import "TrackView.h"
#import "LocusListItem.h"
#import "UIApplication+IGVApplication.h"
#import "RootContentController.h"
#import "IGVContext.h"

@implementation BAMSEGPopupTrackMenuController

#pragma mark - UITableViewDataSource Delegate Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (0 == section) ? 2 : 4;
}

#pragma mark - UITableView Support Methods. Override super class implementation

- (void)presentTableViewCell:(UITableViewCell *)tableViewCell indexPath:(NSIndexPath *)indexPath {

    if (0 == indexPath.section) {
        [super presentTableViewCell:tableViewCell indexPath:indexPath];
        return;
    }

    if (2 == indexPath.row) {

        UILabel *label = [tableViewCell.contentView.subviews objectAtIndex:0];

        TrackView *trackView = self.trackDelegate.track;
        label.text = [[trackView popupMenuItemTitles] objectAtIndex:0];
    } else {

        [super presentTableViewCell:tableViewCell indexPath:indexPath];
        return;
    }

}

- (void)configureTableViewCell:(UITableViewCell *)tableViewCell indexPath:(NSIndexPath *)indexPath {

    if (0 == indexPath.section) {
        [super configureTableViewCell:tableViewCell indexPath:indexPath];
        return;
    }

    TrackView *trackView = self.trackDelegate.track;

    switch (indexPath.row) {

        case 0:
        case 1: {
            [super configureTableViewCell:tableViewCell indexPath:indexPath];
            return;
        }

        case 2: {
            [self.trackDelegate squishExpandTrack:trackView];
        }
            break;

        case 3: {
            double alpha = [UIApplication sharedRootContentController].rootControllerViewLocation.x / CGRectGetWidth([UIApplication sharedRootContentController].view.bounds);

            LocusListItem *currentLocusListItem = [[IGVContext sharedIGVContext] currentLocusListItem];
            double ss = currentLocusListItem.start;
            double ee = currentLocusListItem.end;
            double location = (1.0 - alpha) * ss + alpha * ee;
            [trackView sortFeaturesWithLocation:(long long int) location];
        }
            break;

        default: {
            // nuthin
        }
    }

    [[UIApplication sharedRootContentController].trackMenuPopoverController dismissPopoverAnimated:YES];
    [UIApplication sharedRootContentController].trackMenuPopoverController = nil;

}

@end
