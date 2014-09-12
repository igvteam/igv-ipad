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
//  AlignmentTrack.m
//  HelloAlignment
//
//  Created by turner on 10/16/09.
//  Copyright 2009 Douglass Turner Consulting. All rights reserved.
//
#import "AlignmentTrackView.h"
#import "RefSeqRenderer.h"
#import "AlignmentRenderer.h"
#import "CoverageTrackView.h"
#import "FeatureList.h"
#import "TrackContainerScrollView.h"
#import "UIApplication+IGVApplication.h"
#import "LMResource.h"
#import "TrackDelegate.h"
#import "BAMTrackController.h"
#import "NSUserDefaults+LocusFileURL.h"
#import "LocusListItem.h"
#import "RefSeqTrackView.h"
#import "AlignmentRow.h"
#import "AlignmentResults.h"
#import "NSMutableDictionary+TrackController.h"
#import "RefSeqFeatureList.h"
#import "FeatureInterval.h"
#import "BAMReader.h"
#import "Logging.h"
#import "RefSeqFeatureSource.h"
#import "IGVContext.h"
#import "IGVAppDelegate.h"

@interface AlignmentTrackView ()
- (CGFloat)trackSquishScaleFactor;
@end

@implementation AlignmentTrackView

@synthesize featureList;
@synthesize coverageTrack = _coverageTrack;
@synthesize trackController = _trackController;

- (void) dealloc {

    self.featureList = nil;
    self.coverageTrack = nil;
    self.trackController = nil;

    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame resource:(LMResource *)resource trackDelegate:(TrackDelegate *)trackDelegate trackController:(BAMTrackController *)trackController {
    
    self = [super initWithFrame:frame resource:resource trackDelegate:trackDelegate];
    if (nil != self) {
        self.trackController = trackController;        
    }
    return self;
}

- (void)initializationHelper {

    [super initializationHelper];

    self.renderer = [[[AlignmentRenderer alloc] init] autorelease];

    // track gesture
    [self addGestureRecognizer:[[[UILongPressGestureRecognizer alloc] initWithTarget:[UIApplication sharedRootContentController]
                                                                              action:@selector(presentPopupTrackMenuWithLongPress:)] autorelease]];

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    [rootContentController.trackContainerScrollView addTrack:self];

    // track label
    UILabel *label = [self trackLabelWithText:self.resource.name];
    [self addSubview:label];
    self.trackLabel = label;
    [self bringSubviewToFront:label];

    self.trackLabel.hidden = rootContentController.trackContainerScrollView.trackLabelsAreHidden;

    CoverageTrackView *coverageTrack = [[[CoverageTrackView alloc] initWithFrame:[self coverageTrackFrame]] autorelease];

    [self addSubview:coverageTrack];
    self.coverageTrack = coverageTrack;

}

- (void)drawRect:(CGRect)rect {

    if ([AlignmentTrackView isBelowFeatureRenderingThreshold]) {

        [self.coverageTrack setNeedsDisplay];
        [self.renderer renderInRect:rect featureList:nil trackProperties:nil track:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:TrackDidFinishRenderingNotification object:self];
        return;

    }

    FeatureInterval *currentInterval = [[IGVContext sharedIGVContext] currentFeatureInterval];
    RefSeqTrackView *refSeqTrack = [UIApplication sharedRootContentController].refSeqTrack;

    if (![refSeqTrack.featureSource hasSequenceForInterval:currentInterval]) {

        [refSeqTrack.featureSource loadFeaturesForInterval:currentInterval completion:^() {

            dispatch_async(dispatch_get_main_queue(), ^{
                [self setNeedsDisplay];
            });

        }];

        return;
    }

    BOOL currentFeatureIntervalIsContained = NO;
    if (nil != self.featureList) {
        currentFeatureIntervalIsContained = [self.featureList.featureInterval containsFeatureInterval:currentInterval];
    }

    if (currentFeatureIntervalIsContained) {

        [self.coverageTrack setNeedsDisplay];
        [self.renderer renderInRect:rect featureList:self.featureList trackProperties:nil track:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:TrackDidFinishRenderingNotification object:self];

    } else {

        // NOTE: bamReader uses SAM Tools which do not work properly on a background queue. Have to use main queue. Meh.
        dispatch_async([UIApplication sharedIGVAppDelegate].bamDataRetrievalQueue, ^{

            self.featureList = nil;

            NSError *error = nil;
            AlignmentResults *alignmentResults = [self.trackController.bamReader fetchAlignmentsWithFeatureInterval:currentInterval error:&error];

            if (nil == alignmentResults || nil == alignmentResults.alignments) {

                [[NSNotificationCenter defaultCenter] postNotificationName:TrackDidFinishRenderingNotification object:self];
            } else {

                NSMutableArray *packedAlignments = [alignmentResults packAlignmentsAndDiscardAlignments:YES];

                NSMutableArray *cooked = packedAlignments;
                if (nil != self.trackController.appLaunchLocusCentroid && !self.trackController.didAppLaunchWithLocusCentroid) {
                    cooked = [packedAlignments sortWithBaseAtLocation:self.trackController.appLaunchLocusCentroid coverage:alignmentResults.coverage];
                    self.trackController.didAppLaunchWithLocusCentroid = YES;
                }

                self.featureList = [FeatureList featureListWithFeatureInterval:currentInterval alignments:cooked];
                self.featureList.featureInterval.zoomLevel = -1;

                self.coverageTrack.alignmentResults = alignmentResults;

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setNeedsDisplay];
                });

            }

        });

    }

}

- (CGRect)coverageTrackFrame {
    return CGRectMake(0, CGRectGetMaxY(self.trackLabel.frame), CGRectGetWidth(self.bounds), [CoverageTrackView trackHeight]);
}

- (CGFloat)alignmentReadTemplateHeight {
    return (self.isSquished) ? [self trackSquishScaleFactor] * [AlignmentTrackView rowHeight] : [AlignmentTrackView rowHeight];
}

+ (CGFloat)maximumRows {
    return 50.0;
}

+ (CGFloat)rowHeight {

    static CGFloat height = -1;

    if (height < 0) {
        UILabel *label = [[IGVContext sharedIGVContext].nucleotideLetterLabels objectForKey:@"A"];
        height = CGRectGetHeight(label.bounds) * (2.0/3.0);
    }

    return height;
}

- (CGFloat)trackSquishScaleFactor {
    return 0.25;
}

- (CGFloat)squishedTrackHeight {

    return [self trackSquishScaleFactor] * [AlignmentTrackView trackHeight];
}

- (CGFloat)expandedTrackHeight {

    return [AlignmentTrackView trackHeight];
}

+ (CGFloat)trackHeight {

    CGFloat height = [CoverageTrackView trackHeight] + ([AlignmentTrackView rowHeight] * [AlignmentTrackView maximumRows]);

    CGFloat const whatever = 8; /* whatever */
    CGFloat shimHeight = 60;
    return CGRectGetHeight(CGRectInset(CGRectMake(0, 0, whatever, height), 0, -[TrackView renderSurfaceInsetShimWithTrackRectHeight:shimHeight]));

}

- (void)sortFeaturesWithLocation:(long long int)location {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    if (![rootContentController.refSeqTrack.featureSource referenceSequenceStringExists]) {
        return;
    }

    NSMutableArray *inputAlignments = self.featureList.features;
    NSMutableArray *outputAlignments = [inputAlignments sortWithBaseAtLocation:[NSNumber numberWithLongLong:location] coverage:self.coverageTrack.alignmentResults.coverage];
    self.featureList.features = outputAlignments;

    [rootContentController.trackControllers renderAllTracks];
}

- (NSArray *)popupMenuItemTitles {

    NSMutableArray *titles = [NSMutableArray array];
    [titles addObject:[NSString stringWithFormat:@"%@", (self.isSquished) ? @"Expand" : @"Squish"]];
    [titles addObject:@"Sort"];

    return titles;
}

+(long long int)alignmentVisibilityThreshold {
    return 1000 * [[NSUserDefaults standardUserDefaults] integerForKey:kAlignmentVisibilityThresholdKey];
}

+ (BOOL)isBelowFeatureRenderingThreshold {

//    return [[IGVContext sharedIGVContext] pointsPerBase] < 0.25;
    long long int threshold = [self alignmentVisibilityThreshold];
    return [[IGVContext sharedIGVContext] currentLocusListItem].length > threshold;
}

+(NSDictionary *)alignmentColors {

    return [NSDictionary dictionaryWithObjectsAndKeys:
            [UIColor colorWithRed:238.0 / 255.0 green:243.0 / 255.0 blue:245.0 / 255.0 alpha:1.0], @"light",
            [UIColor colorWithRed:139.0 / 255.0 green:187.0 / 255.0 blue:209.0 / 255.0 alpha:1.0], @"medium",
            [UIColor colorWithRed: 89.0 / 255.0 green:138.0 / 255.0 blue:158.0 / 255.0 alpha:1.0], @"dark",
            [UIColor colorWithRed:  9.0 / 255.0 green: 82.0 / 255.0 blue:109.0 / 255.0 alpha:1.0], @"veryDark",

            [UIColor colorWithRed:  9.0 / 255.0 green: 82.0 / 255.0 blue:109.0 / 255.0 alpha:0.5], @"veryDarkTranslucent",
            [UIColor colorWithRed:127.0 / 255.0 green:127.0 / 255.0 blue:127.0 / 255.0 alpha:0.5], @"grayTranslucent",

            [UIColor colorWithRed: 13.0 /  16.0 green: 13.0 /  16.0 blue: 13.0 /  16.0 alpha:1.0], @"veryLightGray",
            [UIColor colorWithRed: 64.0 / 255.0 green: 64.0 / 255.0 blue: 64.0 / 255.0 alpha:1.0], @"darkGray",

            [UIColor colorWithRed: 64.0 / 255.0 green: 64.0 / 255.0 blue: 64.0 / 255.0 alpha:0.5], @"darkGrayTranslucent",

            [UIColor colorWithWhite:0.25 alpha:1.0], @"grey_dark",
            [UIColor colorWithWhite:0.50 alpha:1.0], @"grey_medium",
            [UIColor colorWithWhite:0.75 alpha:1.0], @"grey_light",
            nil];

}

@end
