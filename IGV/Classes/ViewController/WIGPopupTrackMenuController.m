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
//  WIGPopupTrackMenuController.m
//  IGV
//
//  Created by turner on 5/12/14.
//
//

#import "WIGPopupTrackMenuController.h"
#import "TrackView.h"
#import "TrackDelegate.h"
#import "TrackDataRangeController.h"
#import "FeatureTrackView.h"
#import "DataScale.h"
#import "UIApplication+IGVApplication.h"
#import "RootContentController.h"
#import "NSMutableDictionary+TrackController.h"

@interface WIGPopupTrackMenuController ()
- (void)displayInvalidMaxValue;
@end

@implementation WIGPopupTrackMenuController

#pragma mark - UITableViewDataSource Delegate Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (0 == section) ? 2 : 3;
}

#pragma mark - UITableView Support Methods. Override super class implementation

- (void)configureTableViewCell:(UITableViewCell *)tableViewCell indexPath:(NSIndexPath *)indexPath {

    if (0 == indexPath.section) {
        [super configureTableViewCell:tableViewCell indexPath:indexPath];
        return;
    }

    switch (indexPath.row) {

        case 0:
        case 1: {
            [super configureTableViewCell:tableViewCell indexPath:indexPath];
            return;
        }

        case 2: {
            return;
        }

        default: {
            // nuthin
        }
    }

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    [rootContentController.trackMenuPopoverController dismissPopoverAnimated:YES];
    rootContentController.trackMenuPopoverController = nil;

}

- (void)displayInvalidMaxValue {

    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:nil
                                                     message:@"Max is less than min"
                                                    delegate:nil
                                           cancelButtonTitle:nil
                                           otherButtonTitles:@"OK", nil] autorelease];

    [alert show];
}

#pragma mark - UIStoryboard methods

- (IBAction)unwindControllerWithSeque:(UIStoryboardSegue *)segue {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];

    if ([@"UnwindTrackDataRangeControllerWithCancel" isEqualToString:segue.identifier]) {
        [rootContentController.trackMenuPopoverController dismissPopoverAnimated:YES];
        rootContentController.trackMenuPopoverController = nil;
         return;
    }

    if ([@"UnwindTrackDataRangeControllerWithDone" isEqualToString:segue.identifier]) {

        [rootContentController.trackMenuPopoverController dismissPopoverAnimated:YES];
        rootContentController.trackMenuPopoverController = nil;

        TrackDataRangeController *trackDataRangeController = segue.sourceViewController;
        if (trackDataRangeController.max < trackDataRangeController.min) {
            [self displayInvalidMaxValue];
            return;
        }

        FeatureTrackView *featureTrackView = (FeatureTrackView *)self.trackDelegate.track;
        featureTrackView.doWigFeatureAutoDataScale = trackDataRangeController.doWigFeatureAutoDataScale;
        if (!featureTrackView.doWigFeatureAutoDataScale) {
            featureTrackView.wigFeatureDataScale = [DataScale dataScaleWithMin:trackDataRangeController.min max:trackDataRangeController.max];
        }

        [rootContentController.trackControllers renderTrack:featureTrackView];
        return;
    }

    [super unwindControllerWithSeque:segue];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    UIViewController *vc = segue.destinationViewController;

    if ([@"TrackDataRangeSegue" isEqualToString:segue.identifier]) {

        vc.preferredContentSize = CGSizeMake(300, 256);


        TrackDataRangeController *trackDataRangeController = segue.destinationViewController;

        FeatureTrackView *featureTrackView = (FeatureTrackView *)self.trackDelegate.track;

        trackDataRangeController.doWigFeatureAutoDataScale = featureTrackView.doWigFeatureAutoDataScale;

        trackDataRangeController.max = featureTrackView.wigFeatureDataScale.max;
        trackDataRangeController.min = featureTrackView.wigFeatureDataScale.min;
    }

}

@end
