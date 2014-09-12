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
//  RootContentController.h
//  NestedScrollviewSpike
//
//  Created by Douglass Turner on 01/09/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RootScrollView.h"
#import "TrackView.h"

extern NSString *const TrackDidFinishRenderingNotification;
extern NSString *const DidLaunchApplicationViaURLNotification;

@class FileListItem;
@class RootScrollView;
@class LocusListItem;
@class RefSeqTrackView;
@class TrackController;
@class TrackContainerScrollView;
@class AsciiFeatureSource;
@class SpinnerContainer;
@class LMResource;
@class CytobandTrackView;
@class RulerView;
@class GenomeManager;

@interface RootContentController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate, UIScrollViewDelegate, UIPopoverControllerDelegate>

@property(nonatomic, retain) IBOutlet UITextField *locusTextField;
@property(nonatomic, retain) IBOutlet CytobandTrackView *cytobandTrack;
@property(nonatomic, retain) IBOutlet RootScrollView *rootScrollView;
@property(nonatomic, retain) IBOutlet TrackContainerScrollView *trackContainerScrollView;
@property(nonatomic, retain) IBOutlet RefSeqTrackView *refSeqTrack;
@property(nonatomic, retain) IBOutlet RulerView *rulerView;

@property(nonatomic, assign)          NSUInteger remainingTrackRenderings;
@property(nonatomic, assign)          BOOL allowOrientationChange;

@property(nonatomic, retain)          UIPopoverController *genomeListPopoverController;
@property(nonatomic, retain)          UIPopoverController *trackListPopoverController;
@property(nonatomic, retain)          UIPopoverController *locusListPopoverController;
@property(nonatomic, retain)          UIPopoverController *sessionListPopoverController;
@property(nonatomic, retain)          UIPopoverController *geneNameServicePopoverController;

@property(nonatomic, retain)          NSMutableDictionary *trackControllers;

@property(nonatomic, retain) UIPopoverController *trackMenuPopoverController;
@property(nonatomic) CGPoint rootControllerViewLocation;

- (void)spinnerSpin:(BOOL)spin;

- (void)enableTracksWithResources:(NSArray *)resources appLaunchLocusCentroid:(NSNumber *)appLaunchLocusCentroid;

- (void)discardTrackWithResource:(LMResource *)resource;

- (void)selectLocusListItem:(LocusListItem *)locusListItem;

- (void)genomeSelectionDidChangeWithNotification:(NSNotification *)notification;

- (void)selectGenomeWithGenomeManager:(GenomeManager *)genomeManager locusListItem:(LocusListItem *)locusListItem;

- (void)unwindViewControllerStackWithPopoverController:(UIPopoverController *)popoverController;

- (void)updateZoomSlider;

- (void)captureScreenShot;

- (void)presentPopupTrackMenuWithLongPress:(UILongPressGestureRecognizer *)longPress;

@end