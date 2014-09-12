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
//  IGVRootScrollView.m
//  IGV
//
//  Created by Douglass Turner on 2/6/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "RootScrollView.h"
#import "IGVContext.h"
#import "Cytoband.h"
#import "TrackView.h"
#import "TrackContainerScrollView.h"
#import "GenomeManager.h"
#import "Logging.h"
#import "IGVHelpful.h"
#import "CytobandTrackView.h"
#import "TrackController.h"
#import "FeatureInterval.h"
#import "FeatureTrackView.h"
#import "LocusListItem.h"
#import "NSArray+Cytoband.h"
#import "SelectiveScaleAxisView.h"
#import "RootContentController.h"
#import "UIApplication+IGVApplication.h"
#import "ZoomSlider.h"
#import "UINavigationItem+RootContentController.h"
#import "IGVAppDelegate.h"
#import "UITextField+LocusTextField.h"
#import "CytobandIndicator.h"

double const kRootScrollViewDisplayFullChromosomeThreshold = 0.999;

CGFloat const kRootScrollViewDefaultMinimumZoomScale = 1.0/2.0;
CGFloat const kRootScrollViewDefaultMaximumZoomScale = 2.0/1.0;

//
CGFloat const kRootScrollViewMaximumPointsPerBases = 24.0;

//
CGFloat const kRootScrollViewUnitOfMeasure = 128.0;

// One screenful plus a smidgen in landscape orientation. Units are multiples of kRootScrollViewUnitOfMeasure.
// landscape orientation = 1024 points = 8 * kRootScrollViewUnitOfMeasure
CGFloat const kRootScrollViewUnitOfMeasureScaleFactor = (1.0 + 8.0);

//// One screenful plus a smidgen in landscape orientation. Units are multiples of kRootScrollViewUnitOfMeasure.
//// landscape orientation = 1024 points = 8 * kRootScrollViewUnitOfMeasure
//CGFloat const kRootScrollViewUnitOfMeasureScaleFactor = 8.0;

@interface RootScrollView ()
@property(nonatomic) CGFloat previousPinchGestureScale;
- (void)initializationHelper;

- (void)pinchGestureHandler:(UIPinchGestureRecognizer *)pinchGesture;

- (void)panGestureHandler:(UIPanGestureRecognizer *)panGesture;

- (void)unlockMinify;
- (void)lockMinify;

- (void)clampScrollExtentWithScrollThreshold:(RSVScrollThreshold)aScrollThreshold;
- (void)clampWithOffsetBases:(long long int)offsetBases;

- (void)initializeRubberSheetZoomScale;

- (void)clampScrollRightWithChromosomeEndBases:(long long int)chromosomeEndBases;
- (CGFloat)panCriteriaThreshold;
@end

@implementation RootScrollView

@synthesize contentContainer;
@synthesize contentOffsetForConversionToBase;
@synthesize scrollThreshold;

@synthesize scrollViewZoomScaleBeingSet;

- (void)dealloc {

    self.contentContainer = nil;
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aCoder {

    self = [super initWithCoder:aCoder];
    if (nil != self) {
        [self initializationHelper];
    }
    
    return self;
}

- (void)awakeFromNib {
    [self initializationHelper];
}

- (void)initializationHelper {
    self.contentSize = self.bounds.size;
}

- (void)configureWithRootContentController:(RootContentController *)rootContentController {

    self.minimumZoomScale = kRootScrollViewDefaultMinimumZoomScale;
    self.maximumZoomScale = kRootScrollViewDefaultMaximumZoomScale;

//    ///////////////////////////////////////////////////
//    self.layer.contents = (id) [UIImage imageNamed:@"kidsIcons-translucent"].CGImage;
//    ///////////////////////////////////////////////////

    // One axis scaling - x-axis
    SelectiveScaleAxisView *ssav = (SelectiveScaleAxisView *) self.contentContainer;
    ssav.scaleAxis = EISSelectiveScaleAxisViewAxisX;

    self.contentSize = CGSizeMake([self contentWidth], CGRectGetHeight(self.bounds));

    self.contentContainer.frame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);

//    ///////////////////////////////////////////////////
//    self.contentContainer.layer.contents = (id) [UIImage imageNamed:@"BradWoodstockPeacock-translucent"].CGImage;
//    ///////////////////////////////////////////////////

    // Support single-finger double-tap to magnify 2x.
    UITapGestureRecognizer *singleFingerDoubleTapMagnifyGesture =
            [[[UITapGestureRecognizer alloc] initWithTarget:rootContentController action:@selector(magnifyWithTapGesture:)] autorelease];

    [singleFingerDoubleTapMagnifyGesture setNumberOfTapsRequired:2];
    [singleFingerDoubleTapMagnifyGesture setNumberOfTouchesRequired:1];
    [self.contentContainer addGestureRecognizer:singleFingerDoubleTapMagnifyGesture];

    // Support double-finger single-tap to magnify 2x.
    UITapGestureRecognizer *doubleFingerSingleTapMinifyGesture =
            [[[UITapGestureRecognizer alloc] initWithTarget:rootContentController action:@selector(minifyWithTapGesture:)] autorelease];

    [doubleFingerSingleTapMinifyGesture setNumberOfTapsRequired:1];
    [doubleFingerSingleTapMinifyGesture setNumberOfTouchesRequired:2];

    [self.contentContainer addGestureRecognizer:doubleFingerSingleTapMinifyGesture];
}

-(void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {

    [super addGestureRecognizer:gestureRecognizer];

    [self.panGestureRecognizer   addTarget:self action:@selector(panGestureHandler:)];
    [self.pinchGestureRecognizer addTarget:self action:@selector(pinchGestureHandler:)];

}

- (void)pinchGestureHandler:(UIPinchGestureRecognizer *)pinchGesture {

    LocusListItem *currentLocusListItem = [[IGVContext sharedIGVContext] currentLocusListItem];

    switch (pinchGesture.state) {

        case UIGestureRecognizerStateBegan: {
            self.previousPinchGestureScale = pinchGesture.scale;
        }
            break;

        case UIGestureRecognizerStateChanged: {

            if (LocusListFormatChrFullExtent == currentLocusListItem.locusListFormat && [self pinchGestureIsMagnifying:pinchGesture]) {
                [self lockMinify];
            }

        }
            break;

        case UIGestureRecognizerStateEnded: {
            [self unlockMinify];
        }
            break;

        default: {

        }
            break;
    }

    if (LocusListFormatChrFullExtent != currentLocusListItem.locusListFormat) {
        self.scrollThreshold = [self scrollThresholdCriteria];
        [self clampScrollExtentWithScrollThreshold:self.scrollThreshold];
    }

}

- (void)panGestureHandler:(UIPanGestureRecognizer *)panGesture {

    self.scrollThreshold = [self scrollThresholdCriteria];
    [self clampScrollExtentWithScrollThreshold:self.scrollThreshold];

}

- (BOOL)pinchGestureIsMagnifying:(UIPinchGestureRecognizer *)pinchGesture {

    if (0 == pinchGesture.state) {
        return NO;
    }

    return self.previousPinchGestureScale >= pinchGesture.scale;
}

- (void)unlockMinify {
    self.minimumZoomScale = kRootScrollViewDefaultMinimumZoomScale;
}

- (void)lockMinify {

    [self setZoomScale:self.zoomScale animated:NO];
    self.minimumZoomScale = self.zoomScale;
}

- (void)layoutSubviews {

    [super layoutSubviews];

    // chromosomeName is nil at app startup. This method fires so handle that case.
    if (nil == [IGVContext sharedIGVContext].chromosomeName) {
        return;
    }

    RootContentController *rootContentController = [UIApplication sharedRootContentController];

    LocusListItem *locusListItem = [[IGVContext sharedIGVContext] currentLocusListItem];
    if (LocusListFormatChrFullExtent == locusListItem.locusListFormat && [self pinchGestureIsMagnifying:self.pinchGestureRecognizer]) {

        [rootContentController.trackContainerScrollView maintainStationaryTrackLabelsWithRootScrollView:self];
        return;
    }

    if (RSVScrollThresholdNone == self.scrollThreshold && UIGestureRecognizerStatePossible == self.panGestureRecognizer.state) {

        self.scrollThreshold = [self scrollThresholdCriteria];
        [self clampScrollExtentWithScrollThreshold:self.scrollThreshold];
    }

    double start = 0.0;
    double end = 0.0;
    [self locusWithIGVContextStart:[IGVContext sharedIGVContext].start locusStart:&start locusEnd:&end];

    [rootContentController.cytobandTrack updateWithScrollThreshold:self.scrollThreshold
                                                    chromosomeName:[IGVContext sharedIGVContext].chromosomeName
                                                             start:(long long int) start
                                                               end:(long long int) end];

    [rootContentController.locusTextField updateWithScrollThreshold:self.scrollThreshold
                                                     chromosomeName:[IGVContext sharedIGVContext].chromosomeName
                                                              start:(long long int) start
                                                                end:(long long int) end];

    [rootContentController.trackContainerScrollView maintainStationaryTrackLabelsWithRootScrollView:self];

}

- (CGFloat)derivedMinimumZoomScaleWithCurrentLocusListItem:(LocusListItem *)currentLocusListItem {

    NSArray *chromosomeExtent = [[GenomeManager sharedGenomeManager] currentChromosomeExtent];
    double chromosomeLength = [chromosomeExtent length];

    double currentBases = [currentLocusListItem length];
    double derivedMinimumZoomScale = currentBases/ chromosomeLength;

    return (CGFloat)derivedMinimumZoomScale;
}

- (CGFloat)derivedMaximumZoomScaleWithCurrentLocusListItem:(LocusListItem *)currentLocusListItem {

    CGFloat currentBases = [currentLocusListItem length];
    CGFloat thresholdBases = CGRectGetWidth(self.bounds)/kRootScrollViewMaximumPointsPerBases;
    CGFloat derivedMaximumZoomScale = currentBases/thresholdBases;

    return derivedMaximumZoomScale;
}

- (RSVScrollThreshold)scrollThresholdCriteria {

    double locusStart;
    double locusEnd;
    [self locusWithIGVContextStart:[IGVContext sharedIGVContext].start locusStart:&locusStart locusEnd:&locusEnd];

    double locusLength = locusEnd - locusStart;

    NSArray *chromosomeExtent = [[GenomeManager sharedGenomeManager] currentChromosomeExtent];
    double chromosomeLength = [chromosomeExtent length];

    double zoomRatio = chromosomeLength / locusLength;

    if (zoomRatio <= 1.0) {

        return RSVScrollThresholdLeftAndRight;
    } else if (locusStart <= [chromosomeExtent start]) {

        return RSVScrollThresholdLeft;
    } else if (locusEnd >= [chromosomeExtent end]) {

        return RSVScrollThresholdRight;
    }

    return RSVScrollThresholdNone;
}

- (void)clampScrollExtentWithScrollThreshold:(RSVScrollThreshold)aScrollThreshold {


    NSArray *chromosomeExtent = [[GenomeManager sharedGenomeManager] currentChromosomeExtent];

    switch (aScrollThreshold) {

        case RSVScrollThresholdUnevaluated:
        case RSVScrollThresholdNone:
            break;

        case RSVScrollThresholdLeft:
        {
            [self clampWithOffsetBases:(-[IGVContext sharedIGVContext].start)];
        }
            break;

        case RSVScrollThresholdRight:
        {
            [self clampScrollRightWithChromosomeEndBases:[chromosomeExtent end]];
        }
            break;

        case RSVScrollThresholdLeftAndRight:
        {

            LocusListItem *locusListItem = [[IGVContext sharedIGVContext] currentLocusListItem];
            locusListItem.locusListFormat = LocusListFormatChrStartEnd;
            locusListItem.start += 32;
            locusListItem.end   -= 32;
            [self setContentOffsetWithLocusListItem:locusListItem disableUI:NO];

        }
            break;

        default:
            break;

    }

}

- (void)clampScrollRightWithChromosomeEndBases:(long long int)chromosomeEndBases {

    double screenLeftBases = (double) chromosomeEndBases - [self bases:CGRectGetWidth(self.bounds)];
    double startBases = (double) [IGVContext sharedIGVContext].start;
    double offsetBases = screenLeftBases - startBases;

    [self clampWithOffsetBases:(long long int)offsetBases];
}

- (void)clampWithOffsetBases:(long long int)offsetBases {
    double offsetPoints = [[IGVContext sharedIGVContext] pointsPerBase] * offsetBases;
    [self setContentOffset:CGPointMake((CGFloat) offsetPoints, self.contentOffset.y) animated:NO];
}

- (void)setContentOffsetWithLocusListItem:(LocusListItem *)locusListItem disableUI:(BOOL)disableUI {

    if (nil == locusListItem) {
        return;
    }

    self.scrollThreshold = RSVScrollThresholdUnevaluated;

    double locusOffsetComparison;
    IGVContext *igvContext = [IGVContext sharedIGVContext];
    [igvContext setWithLocusStart:locusListItem.start locusEnd:locusListItem.end locusOffsetComparisonBases:&locusOffsetComparison];

    if (disableUI) {
        [[UIApplication sharedIGVAppDelegate] disableUserInteraction];
    }

    [self initializeRubberSheetZoomScale];

    CGPoint offset;
    if (locusOffsetComparison > locusListItem.start) {

        offset = CGPointMake((CGFloat)([igvContext pointsPerBase] * locusListItem.start), self.contentOffset.y);
    } else if (locusOffsetComparison > [[GenomeManager sharedGenomeManager] deltaBetweenEndOfChromosomeName:igvContext.chromosomeName andValue:locusListItem.end]) {

        CGFloat ox = self.contentSize.width - CGRectGetWidth(self.bounds);
        ox -= ([igvContext pointsPerBase] * ((CGFloat) [[GenomeManager sharedGenomeManager] deltaBetweenEndOfChromosomeName:igvContext.chromosomeName andValue:locusListItem.end]));

        offset = CGPointMake(ox, self.contentOffset.y);
    } else {

        offset = [self contentOffsetForCenteredContent];
    }

    [self setContentOffset:offset animated:NO];

    [[UIApplication sharedRootContentController] updateZoomSlider];

    [self setNeedsLayout];

}

- (void)initializeRubberSheetZoomScale {
    self.scrollViewZoomScaleBeingSet = YES;
    [self setZoomScale:1 animated:NO];
    self.scrollViewZoomScaleBeingSet = NO;
}

- (void)locusWithIGVContextStart:(long long int)igvContextStart locusStart:(double *)locusStart locusEnd:(double *)locusEnd {

    *locusStart = ((double) igvContextStart);
    *locusStart += [self bases:self.contentOffsetForConversionToBase.x];

    *locusEnd = *locusStart;
    *locusEnd += [self bases:CGRectGetWidth(self.bounds)];

    NSArray *chromosomeExtent = [[GenomeManager sharedGenomeManager] currentChromosomeExtent];

    if (nil == chromosomeExtent) {

        *locusStart = 0;
        *locusEnd = 0;
        return;
    }

    *locusStart = MAX(*locusStart,  (double)[chromosomeExtent start]);
    *locusEnd = MIN(*locusEnd, (double)[chromosomeExtent   end]);

}

- (CGPoint)contentOffsetForCenteredContent {

    CGFloat dx = ( self.contentSize.width -  CGRectGetWidth(self.bounds)) / 2;
    CGFloat dy = (self.contentSize.height - CGRectGetHeight(self.bounds)) / 2;
    return CGPointMake(dx, dy);
}

- (void)setContentOffset:(CGPoint)aContentOffset {

    [super setContentOffset:aContentOffset];
    self.contentOffsetForConversionToBase = aContentOffset;
}

- (void)setContentOffset:(CGPoint)aContentOffset animated:(BOOL)animated {

    [super setContentOffset:aContentOffset animated:animated];
    self.contentOffsetForConversionToBase = aContentOffset;
}

- (CGFloat)contentOffsetRightWithContentOffsetLeft:(CGFloat)contentOffsetLeft {

    return self.contentSize.width - CGRectGetWidth(self.bounds) - contentOffsetLeft;
}

#pragma mark - Screen Metrics Methods

- (NSInteger)rootScrollViewWidthUnitOfMeasureMultiple {

    NSInteger multiple = (NSInteger)CGRectGetWidth(self.bounds);
    return multiple/((NSInteger)kRootScrollViewUnitOfMeasure);
}

- (double)locusOffsetUsingRootScrollviewUnitOfMeasturePoints {

    double result = 0.0;

    // Portrait orientation
    if (6 == [self rootScrollViewWidthUnitOfMeasureMultiple]) {

        result =  (kRootScrollViewUnitOfMeasureScaleFactor) * kRootScrollViewUnitOfMeasure;
    }

    // Landscape orientation
    if (8 == [self rootScrollViewWidthUnitOfMeasureMultiple]) {

        result =  (kRootScrollViewUnitOfMeasureScaleFactor - 1) * kRootScrollViewUnitOfMeasure;
    }

    return result;
}

-(CGFloat)contentWidth {

//    CGRect windowBounds = [[[UIApplication sharedApplication] delegate] window].bounds;
    CGRect windowBounds = [[[UIApplication sharedApplication] delegate] window].bounds;
    CGFloat screenSegment = MIN(CGRectGetWidth(windowBounds), CGRectGetHeight(windowBounds));

    CGFloat outrigger = kRootScrollViewUnitOfMeasureScaleFactor * kRootScrollViewUnitOfMeasure;

    return outrigger + screenSegment + outrigger;
 }

- (double)bases:(double)points {
    return points / [[IGVContext sharedIGVContext] pointsPerBase];
}

- (RootScrollViewPanCriteria)panCriteria {

    if (nil == [IGVContext sharedIGVContext].chromosomeName || self.scrollViewZoomScaleBeingSet || self.isZooming) {
        return RootScrollViewPanCriteriaUnmet;
    }

    CGFloat leftOffset = self.contentOffset.x;
    CGFloat rightOffset = [self contentOffsetRightWithContentOffsetLeft:self.contentOffset.x];

    // rubber sheet is at left limit
    if (leftOffset < [self panCriteriaThreshold]) {

        if ([IGVContext sharedIGVContext].start < 1) {

            [self setContentOffset:self.contentOffset animated:NO];
            return RootScrollViewPanCriteriaUnmet;
        }

        return RootScrollViewPanCriteriaMetOnLeft;
    }

    // rubber sheet is at right limit
    if (rightOffset < [self panCriteriaThreshold]) {

        NSArray *chromosomeExtent = [[GenomeManager sharedGenomeManager] currentChromosomeExtent];

        if ([IGVContext sharedIGVContext].end > ([chromosomeExtent end] - 1)) {

            [self setContentOffset:self.contentOffset animated:NO];
            return RootScrollViewPanCriteriaUnmet;
        }

        return RootScrollViewPanCriteriaMetOnRight;
    }

    return RootScrollViewPanCriteriaUnmet;
}

- (CGFloat)panCriteriaThreshold {
    return 1.0;
}

- (BOOL)willDisplayEntireChromosomeName:(NSString *)chromosomeName start:(double)start end:(double)end {

    NSArray *chromosomeExtent = [[GenomeManager sharedGenomeManager] chromosomeExtentWithChromosomeName:chromosomeName];
    double chromosomeCoveragePercentage = (end - start) / (double)([chromosomeExtent length]);
    return chromosomeCoveragePercentage > kRootScrollViewDisplayFullChromosomeThreshold;

}

- (NSString *)description {

    LocusListItem *currentLocusListItem = [[IGVContext sharedIGVContext] currentLocusListItem];
    return [NSString stringWithFormat:@"%@ min|min-derived %.3f | %.3f    zoomLevel %.3f    max|max-derived %.3f | %.3f.",
                    [self class],
                    self.minimumZoomScale, [self derivedMinimumZoomScaleWithCurrentLocusListItem:currentLocusListItem],
                    self.zoomScale,
                    self.maximumZoomScale, [self derivedMaximumZoomScaleWithCurrentLocusListItem:currentLocusListItem]];
}

@end
