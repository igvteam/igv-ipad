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
// Created by turner on 11/20/13.
//

#import "SEGTrackView.h"
#import "RefSeqTrackController.h"
#import "SEGRenderer.h"
#import "SEGFeatureSource.h"
#import "TrackDelegate.h"
#import "FeatureInterval.h"
#import "IGVContext.h"
#import "UIApplication+IGVApplication.h"
#import "EraseRenderer.h"
#import "TrackContainerScrollView.h"
#import "LMResource.h"
#import "Logging.h"
#import "NSMutableDictionary+TrackController.h"

@interface SEGTrackView ()
@property(nonatomic) BOOL dormant;
@property(nonatomic, retain) EraseRenderer *eraseRenderer;
+ (CGFloat)sampleRowHeight;
+ (CGFloat)squishedSampleRowHeight;
+ (CGFloat)expandedSampleRowHeight;
@end

@implementation SEGTrackView

@synthesize dormant = _dormant;

- (void)dealloc {

    self.eraseRenderer = nil;
    [super dealloc];
}

- (void)initializationHelper {

    [super initializationHelper];

    self.renderer = [[[SEGRenderer alloc] init] autorelease];
    self.eraseRenderer = [[[EraseRenderer alloc] initWithEraseColor:[UIColor whiteColor]] autorelease];


    self.dormant = YES;

    // The bit below is copied from FeatureTrackView.  Perhaps it should be moved up to TrackView?
    // track gesture
    [self addGestureRecognizer:[[[UILongPressGestureRecognizer alloc] initWithTarget:[UIApplication sharedRootContentController]
                                                                              action:@selector(presentPopupTrackMenuWithLongPress:)] autorelease]];

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    [rootContentController.trackContainerScrollView addTrack:self];

    // track label
    UILabel *label = [self trackLabelWithText:self.resource.name];
    [self addSubview:label];
    self.trackLabel = label;
    [self bringSubviewToFront:self.trackLabel];

    self.trackLabel.hidden = rootContentController.trackContainerScrollView.trackLabelsAreHidden;


}

- (void)sortFeaturesWithLocation:(long long int)location {

    if (nil == self.featureSource) return;

    [self.featureSource sortSamplesWithLocation:location];

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    [rootContentController.trackControllers renderAllTracks];
}

- (void)drawRect:(CGRect)rect {

    if (nil == self.featureSource) {

        [self.eraseRenderer renderInRect:rect featureList:nil trackProperties:nil track:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:TrackDidFinishRenderingNotification object:self];
        return;
    }

    FeatureInterval *currentFeatureInterval = [[IGVContext sharedIGVContext] currentFeatureInterval];

    NSDictionary *sampleRows = [self.featureSource featuresForFeatureInterval:currentFeatureInterval];

    NSArray *sampleNames = self.featureSource.sampleNames;

    if (nil != sampleRows) {

        if (self.dormant) {

            self.dormant = !(self.dormant);

            CGFloat height = (self.isSquished) ? [self squishedTrackHeight] : [self expandedTrackHeight];
            [self.trackDelegate animateTrack:self toTargetHeight:height];

        } else {


            [self.renderer renderInRect:rect sampleRows:sampleRows sampleNames:sampleNames];

            [[NSNotificationCenter defaultCenter] postNotificationName:TrackDidFinishRenderingNotification object:self];
        }

    } else {

        self.dormant = YES;
        self.featureSource.samples = nil;

        [self.featureSource loadFeaturesForInterval:currentFeatureInterval completion:^() {

            dispatch_async(dispatch_get_main_queue(), ^{

                [self setNeedsDisplay];

                // Note -- We would like to do something like this instead of setNeedsDisplay, but it doesn't work.
                // [self.renderer renderInRect:rect samples:segSamples track:self];
            });

        }];
    }

}

- (NSUInteger)sampleRowCount {
    return [[self.featureSource sampleNames] count];
}

// The default height
+ (CGFloat)trackHeight {
    return 60;
}

- (CGFloat)squishedTrackHeight {

    ALog(@"squishedSampleRowHeight * sampleRowCount = %.0f * %lu = %.0f",
    [SEGTrackView squishedSampleRowHeight],
    (unsigned long)[self sampleRowCount],
    [SEGTrackView squishedSampleRowHeight] * [self sampleRowCount]);

    CGFloat rawHeight = [SEGTrackView squishedSampleRowHeight] * [self sampleRowCount];

    ALog(@"WARNING: Clamp %.0f to %d", rawHeight, 4096);
    return MIN(4096, rawHeight);

}

- (CGFloat)expandedTrackHeight {

    ALog(@"expandedSampleRowHeight * sampleRowCount = %.0f * %lu = %.0f",
    [SEGTrackView expandedSampleRowHeight],
    (unsigned long)[self sampleRowCount],
    [SEGTrackView expandedSampleRowHeight] * [self sampleRowCount]);

    CGFloat rawHeight = [SEGTrackView expandedSampleRowHeight] * [self sampleRowCount];

    ALog(@"WARNING: Clamp %.0f to %d", rawHeight, 4096);
    return MIN(4096, rawHeight);
//    return [SEGTrackView expandedSampleRowHeight] * [self sampleRowCount];
}

+ (CGFloat)squishedSampleRowHeight {
    return 1;
}

+ (CGFloat)expandedSampleRowHeight {
    return [self sampleRowHeight];
}

+ (CGFloat)sampleRowHeight {
    return 12;
}

- (NSArray *)popupMenuItemTitles {

    NSMutableArray *titles = [NSMutableArray array];
    [titles addObject:[NSString stringWithFormat:@"%@", (self.isSquished) ? @"Expand" : @"Squish"]];
    [titles addObject:(self.featureSource.reverseSortOrder) ? @"Sort Acending" : @"Sort Decending"];

    return titles;
}

@end