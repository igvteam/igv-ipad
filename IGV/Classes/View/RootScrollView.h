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
//  IGVRootScrollView.h
//  IGV
//
//  Created by Douglass Turner on 2/6/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    RootScrollViewPanCriteriaUnmet = 1,
    RootScrollViewPanCriteriaMetOnLeft = 2,
    RootScrollViewPanCriteriaMetOnRight = 4
} RootScrollViewPanCriteria;

@class IGVContext;
@class LocusListItem;
@class RootContentController;

extern double const kRootScrollViewDisplayFullChromosomeThreshold;
extern CGFloat const kRootScrollViewDefaultMinimumZoomScale;
extern CGFloat const kRootScrollViewDefaultMaximumZoomScale;
extern CGFloat const kRootScrollViewMaximumPointsPerBases;

typedef enum {
    RSVScrollThresholdUnevaluated  =  (NSUInteger)0,
    RSVScrollThresholdNone         = ((NSUInteger)1 <<  1),
    RSVScrollThresholdLeft         = ((NSUInteger)1 <<  2),
    RSVScrollThresholdRight        = ((NSUInteger)1 <<  3),
    RSVScrollThresholdLeftAndRight = ((NSUInteger)1 <<  4)
} RSVScrollThreshold;

@interface RootScrollView : UIScrollView

@property(nonatomic, retain) IBOutlet UIView *contentContainer;
@property(nonatomic, assign) CGPoint            contentOffsetForConversionToBase;
@property(nonatomic, assign) RSVScrollThreshold scrollThreshold;
@property(nonatomic, assign) BOOL               scrollViewZoomScaleBeingSet;

- (void)configureWithRootContentController:(RootContentController *)rootContentController;

- (CGFloat)contentOffsetRightWithContentOffsetLeft:(CGFloat)contentOffsetLeft;
- (BOOL)pinchGestureIsMagnifying:(UIPinchGestureRecognizer *)pinchGesture;
- (RSVScrollThreshold)scrollThresholdCriteria;

- (void)setContentOffsetWithLocusListItem:(LocusListItem *)locusListItem disableUI:(BOOL)disableUI;

- (void)locusWithIGVContextStart:(long long int)igvContextStart locusStart:(double *)locusStart locusEnd:(double *)locusEnd;
- (CGPoint)contentOffsetForCenteredContent;

- (NSInteger)rootScrollViewWidthUnitOfMeasureMultiple;
- (double)locusOffsetUsingRootScrollviewUnitOfMeasturePoints;

- (CGFloat)contentWidth;
- (double)bases:(double)points;
- (RootScrollViewPanCriteria)panCriteria;

- (BOOL)willDisplayEntireChromosomeName:(NSString *)chromosomeName start:(double)start end:(double)end;

- (CGFloat)derivedMinimumZoomScaleWithCurrentLocusListItem:(LocusListItem *)currentLocusListItem;
- (CGFloat)derivedMaximumZoomScaleWithCurrentLocusListItem:(LocusListItem *)currentLocusListItem;
@end
