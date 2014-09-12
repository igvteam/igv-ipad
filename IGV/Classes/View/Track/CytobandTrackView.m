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
//  CytobandTrack.m
//  ParseCytoband
//
//  Created by turner on 9/11/09.
//  Copyright 2009 Douglass Turner Consulting. All rights reserved.
//

#import "CytobandTrackView.h"
#import "Cytoband.h"
#import "IGVMath.h"
#import "IGVContext.h"
#import "CytobandIndicator.h"
#import "GenomeManager.h"
#import "NSArray+Cytoband.h"
#import "LocusListItem.h"
#import "NSMutableDictionary+TrackController.h"
#import "UIApplication+IGVApplication.h"

@interface CytobandTrackView (Interaction)
- (void)tapToNavigateGestureHandler:(UITapGestureRecognizer *)tapGesture;
- (void)updateIndicatorLocusStart:(long long int)locusStart locusEnd:(long long int)locusEnd;
@end

@interface CytobandTrackView (Render)
- (void)clipWithRoundedRectInContext:(CGContextRef)context renderRect:(CGRect)renderRect;
- (void)borderWithRoundedRectInContext:(CGContextRef)context renderRect:(CGRect)renderRect;
- (void)clippingPathInContext:(CGContextRef)aContext scaleFactor:(CGSize)scaleFactor displayBBox:(CGRect)displayBBox acenPair:(NSArray *)aAcenPair;
- (void)borderInContext:(CGContextRef)aContext scaleFactor:(CGSize)scaleFactor displayBBox:(CGRect)displayBBox acenPair:(NSArray *)aAcenPair;
@end

@implementation CytobandTrackView

@synthesize indicator = _indicator;

- (void)dealloc {

    self.indicator = nil;

    [super dealloc];
}

- (void)initializationHelper {
    [super initializationHelper];

    UITapGestureRecognizer *tapGestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToNavigateGestureHandler:)] autorelease];
    [self addGestureRecognizer:tapGestureRecognizer];
}

#pragma mark - Tap to Navigate

- (void)tapToNavigateGestureHandler:(UITapGestureRecognizer *)tapGesture {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];

    double locusStart;
    double locusEnd;
    [rootContentController.rootScrollView locusWithIGVContextStart:[IGVContext sharedIGVContext].start locusStart:&locusStart locusEnd:&locusEnd];

    if ([rootContentController.rootScrollView willDisplayEntireChromosomeName:[IGVContext sharedIGVContext].chromosomeName start:locusStart end:locusEnd]) {
        return;
    }

    LocusListItem *currentLocusListItem = [LocusListItem locusListItemWithChromosomeName:[IGVContext sharedIGVContext].chromosomeName
                                                                                   start:(long long int) nearbyint(locusStart)
                                                                                     end:(long long int) nearbyint(locusEnd)
                                                                              genomeName:[GenomeManager sharedGenomeManager].currentGenomeName];

    CGFloat numer = [tapGesture locationInView:self].x - CGRectGetMinX(self.bounds);
    CGFloat denom = CGRectGetWidth(self.bounds);
    LocusListItem *locusListItem = [currentLocusListItem locusListItemWithCentroidPercentage:(numer/denom)];

    [[UIApplication sharedRootContentController] captureScreenShot];

    [self updateIndicatorLocusStart:locusListItem.start locusEnd:locusListItem.end];

    [rootContentController.rootScrollView setContentOffsetWithLocusListItem:locusListItem disableUI:YES];
    [rootContentController.trackControllers renderAllTracks];

}

#pragma mark - Cytoband Navigator Update

- (void)updateIndicatorLocusStart:(long long int)locusStart locusEnd:(long long int)locusEnd {

    double locusWidth = (locusEnd - locusStart);
    double chromosomeLength = [[[GenomeManager sharedGenomeManager] currentChromosomeExtent] length];

    CGFloat originXPercentage = (CGFloat)(locusStart/chromosomeLength);
    CGPoint origin = CGPointMake(originXPercentage * CGRectGetWidth(self.bounds), 0);

    CGFloat widthPercentage = (CGFloat)(locusWidth/chromosomeLength);
    CGFloat width = MAX([CytobandIndicator minimumWidth], widthPercentage * CGRectGetWidth(self.bounds));
    self.indicator.frame = [IGVMath rectWithOrigin:origin size:CGSizeMake(width, CGRectGetHeight(self.bounds))];

    [self setNeedsDisplay];
}

- (void)updateWithScrollThreshold:(RSVScrollThreshold)scrollThreshold chromosomeName:(NSString *)chromosomeName start:(long long int)start end:(long long int)end {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    if ([rootContentController.rootScrollView willDisplayEntireChromosomeName:chromosomeName start:start end:end]) {

        self.indicator.hidden = YES;
        return;
    }

    NSArray *chromosomeExtent = [[GenomeManager sharedGenomeManager] chromosomeExtentWithChromosomeName:chromosomeName];

    switch (scrollThreshold) {

        case RSVScrollThresholdUnevaluated:
        case RSVScrollThresholdNone:
            break;

        case RSVScrollThresholdLeftAndRight:
        {
            start = [chromosomeExtent start];
            end   = [chromosomeExtent end];
        }
            break;

        case RSVScrollThresholdRight:
        {
            end = [chromosomeExtent end];
        }
            break;

        case RSVScrollThresholdLeft:
        {
            start = [chromosomeExtent start];
        }
            break;

        default:
            return;
    }

    self.indicator.hidden = NO;
    [self updateIndicatorLocusStart:start locusEnd:end];

}

#pragma mark -
#pragma mark CytobandView Rendering Methods

- (void)drawRect:(CGRect)rect {

    if (nil == [[GenomeManager sharedGenomeManager] currentCytoband]) {
        [self fastaSequenceRenderWithRect:rect];
        return;
    }

    NSArray *rectangleListTemplate = [[[GenomeManager sharedGenomeManager] currentCytoband] rectangleListTemplateForChromosomeName:[IGVContext sharedIGVContext].chromosomeName];

    if (nil == rectangleListTemplate || 0 == [rectangleListTemplate count]) {
        return;
    }

    [[UIColor clearColor] setFill];
    UIRectFill(rect);

    CGContextRef context = UIGraphicsGetCurrentContext();

    // Render the centomere ellipses
    NSMutableArray *acenPair = [NSMutableArray array];
    for (NSArray *rectangleDescription in rectangleListTemplate) {

        if ([[rectangleDescription objectAtIndex:1] isEqualToString:@"acen"]) {
            [acenPair addObject:rectangleDescription];
        }
    }

    // Calc. bbox of data and self.view to compute the scale factor for drawing
    CGRect dataBBox = [rectangleListTemplate bbox];

    CGRect displayBBox = CGRectInset(rect, 1, 2);

    CGSize scaleFactor;
    scaleFactor.width = CGRectGetWidth(displayBBox) / CGRectGetWidth(dataBBox);
    scaleFactor.height = CGRectGetHeight(displayBBox) / CGRectGetHeight(dataBBox);

    if ([acenPair count] == 2) {

        [self clippingPathInContext:context
                        scaleFactor:scaleFactor
                        displayBBox:displayBBox
                           acenPair:acenPair];
    } else {

        [self clipWithRoundedRectInContext:context renderRect:displayBBox];
    }

    NSDictionary *chromosomeColorNames = [[GenomeManager sharedGenomeManager] currentCytoband].colorNames;

    for (NSArray *rectangleDescription in rectangleListTemplate) {

        // Scale the rectangle
        CGRect r = [[rectangleDescription objectAtIndex:0] CGRectValue];
        r.origin.x *= scaleFactor.width;

        r.origin.x += displayBBox.origin.x;
        r.origin.y += displayBBox.origin.y;

        r.size.width *= scaleFactor.width;
        r.size.height *= scaleFactor.height;

        [[chromosomeColorNames objectForKey:[rectangleDescription objectAtIndex:1]] setFill];
//        [[UIColor randomRGBWithAlpha:1] setFill];
        CGContextFillRect(context, r);

    } // for (rectangleListTemplate)

    if ([acenPair count] == 2) {

        [self borderInContext:context
                  scaleFactor:scaleFactor
                  displayBBox:displayBBox
                     acenPair:acenPair];
    } else {

        [self borderWithRoundedRectInContext:context renderRect:displayBBox];
    }

}

- (void)fastaSequenceRenderWithRect:(CGRect)rect {

    CGContextRef context = UIGraphicsGetCurrentContext();

    [self clipWithRoundedRectInContext:context renderRect:CGRectInset(rect, 1, 2)];

    [[UIColor whiteColor] setFill];
//    [[UIColor greenColor] setFill];
    UIRectFill(rect);

    [self borderWithRoundedRectInContext:context renderRect:CGRectInset(rect, 1, 2)];

}

- (void)clipWithRoundedRectInContext:(CGContextRef)context renderRect:(CGRect)renderRect {

    float radius		= CGRectGetHeight(renderRect)/2.0;
    float arcCenterY	= CGRectGetMinY(renderRect) + radius;

    float  leftArcCenterX	= CGRectGetMinX(renderRect) + radius;
    float rightArcCenterX	= CGRectGetMaxX(renderRect) - radius;

    CGContextBeginPath(context);

    CGContextAddArc(context,  leftArcCenterX, arcCenterY, radius, [IGVMath radians:0], [IGVMath radians:360], 0);

    CGContextAddRect(context, CGRectMake(leftArcCenterX, CGRectGetMinY(renderRect), CGRectGetWidth(renderRect) - CGRectGetHeight(renderRect), CGRectGetHeight(renderRect)));

    CGContextAddArc(context, rightArcCenterX, arcCenterY, radius, [IGVMath radians:0], [IGVMath radians:360], 0);

    CGContextClip(context);

}

- (void)borderWithRoundedRectInContext:(CGContextRef)context renderRect:(CGRect)renderRect {

    float radius		= CGRectGetHeight(renderRect)/2.0;
    float arcCenterY	= CGRectGetMinY(renderRect) + radius;

    float  leftArcCenterX	= CGRectGetMinX(renderRect) + radius;
    float rightArcCenterX	= CGRectGetMaxX(renderRect) - radius;

    CGContextBeginPath(context);
    CGContextMoveToPoint (context, leftArcCenterX, arcCenterY + radius);
    CGContextAddArc(context, leftArcCenterX, arcCenterY, radius, [IGVMath radians:90], [IGVMath radians:270], 0);

    CGContextMoveToPoint (context, rightArcCenterX, arcCenterY + radius);
    CGContextAddArc(context, rightArcCenterX, arcCenterY, radius, [IGVMath radians:90], [IGVMath radians:270], 1);


    CGFloat endX = (CGRectGetWidth(renderRect) - radius)/0.99;

       CGContextMoveToPoint(context, leftArcCenterX, CGRectGetMinY(renderRect));
    CGContextAddLineToPoint(context,           endX, CGRectGetMinY(renderRect));

       CGContextMoveToPoint(context, leftArcCenterX, CGRectGetMaxY(renderRect));
    CGContextAddLineToPoint(context,           endX, CGRectGetMaxY(renderRect));

    CGContextSetLineWidth(context, 2);
    [[UIColor blackColor] setStroke];
    CGContextStrokePath(context);

}

- (void)clippingPathInContext:(CGContextRef)aContext scaleFactor:(CGSize)scaleFactor displayBBox:(CGRect)displayBBox acenPair:(NSArray *)aAcenPair {

	float radius		= CGRectGetHeight(displayBBox)/2.0;
	float arcCenterY	= displayBBox.origin.y + radius;
	
	float  leftArcCenterX	=  displayBBox.origin.x + radius;
	float rightArcCenterX	= (displayBBox.origin.x + displayBBox.size.width) - radius;
	
	CGContextBeginPath(aContext);
	
	CGContextAddArc(aContext,  leftArcCenterX, arcCenterY, radius, [IGVMath radians:0], [IGVMath radians:360], 0);
	CGContextAddArc(aContext, rightArcCenterX, arcCenterY, radius, [IGVMath radians:0], [IGVMath radians:360], 0);
	
	for (NSUInteger i = 0; i < [aAcenPair count]; i++) {
		
		NSArray *acen = [aAcenPair objectAtIndex:i];
		CGRect acenRect			= [[acen objectAtIndex:0] CGRectValue];
		acenRect.origin.x		*= scaleFactor.width;
		
		acenRect.origin.x += displayBBox.origin.x;
		acenRect.origin.y += displayBBox.origin.y;
		
		acenRect.size.width		*= scaleFactor.width;
		acenRect.size.height	*= scaleFactor.height;
		
		float exe;
		if (i == 0) {
			
			// Draw left rect
			exe = (acenRect.origin.x + acenRect.size.width) - radius;
			CGContextAddRect(aContext,
							 CGRectMake(
										// origin
										leftArcCenterX, displayBBox.origin.y,
										// size
										exe - (leftArcCenterX), displayBBox.size.height));
		} else {
			
			// Draw right rect
			exe = acenRect.origin.x + radius;
			CGContextAddRect(aContext,
							 CGRectMake(
										// origin
										exe, displayBBox.origin.y,
										// size
										((displayBBox.origin.x + displayBBox.size.width) - radius) - exe, displayBBox.size.height));
		}
		
		// Acen disks
		CGContextAddArc(aContext, exe, arcCenterY, radius, [IGVMath radians:0], [IGVMath radians:360], 0);
		
	} // for ([aAcenPair count])
	
	CGContextClip(aContext);
}

- (void)borderInContext:(CGContextRef)aContext scaleFactor:(CGSize)scaleFactor displayBBox:(CGRect)displayBBox acenPair:(NSArray *)aAcenPair {

	float radius		= displayBBox.size.height/2.0;
	float arcCenterY	= displayBBox.origin.y + radius;
	
	float  leftArcCenterX	=  displayBBox.origin.x + radius;
	float rightArcCenterX	= (displayBBox.origin.x + displayBBox.size.width) - radius;
	
	CGContextBeginPath(aContext);
	CGContextMoveToPoint (aContext, leftArcCenterX, arcCenterY + radius);
	CGContextAddArc(aContext, leftArcCenterX, arcCenterY, radius, [IGVMath radians:90], [IGVMath radians:270], 0);

	CGContextMoveToPoint (aContext, rightArcCenterX, arcCenterY + radius);
	CGContextAddArc(aContext, rightArcCenterX, arcCenterY, radius, [IGVMath radians:90], [IGVMath radians:270], 1);
	
	for (NSUInteger i = 0; i < [aAcenPair count]; i++) {
		
		NSArray *acen = [aAcenPair objectAtIndex:i];
		CGRect acenRect			= [[acen objectAtIndex:0] CGRectValue];
		acenRect.origin.x		*= scaleFactor.width;
		
		acenRect.origin.x += displayBBox.origin.x;
		acenRect.origin.y += displayBBox.origin.y;
		
		acenRect.size.width		*= scaleFactor.width;
		acenRect.size.height	*= scaleFactor.height;
		
		float exe;
		if (i == 0) {
			
			// Draw left rect
			exe = (acenRect.origin.x + acenRect.size.width) - radius;
			
			CGContextMoveToPoint (aContext, exe, arcCenterY + radius);
			CGContextAddArc(aContext, exe, arcCenterY, radius, [IGVMath radians:90], [IGVMath radians:270], 1);
			
			   CGContextMoveToPoint(aContext, leftArcCenterX, displayBBox.origin.y);
			CGContextAddLineToPoint(aContext,            exe, displayBBox.origin.y);
			
			   CGContextMoveToPoint(aContext, leftArcCenterX, displayBBox.origin.y + displayBBox.size.height);
			CGContextAddLineToPoint(aContext,            exe, displayBBox.origin.y + displayBBox.size.height);
			
			
		} else {
			
			// Draw right rect
			exe = acenRect.origin.x + radius;
			
			CGContextMoveToPoint (aContext, exe, arcCenterY + radius);
			CGContextAddArc(aContext, exe, arcCenterY, radius, [IGVMath radians:90], [IGVMath radians:270], 0);
			
			   CGContextMoveToPoint(aContext,                                                                  exe, displayBBox.origin.y);
			CGContextAddLineToPoint(aContext, ((displayBBox.origin.x + displayBBox.size.width) - radius), displayBBox.origin.y);
			
			   CGContextMoveToPoint(aContext,                                                                  exe,
									displayBBox.origin.y + displayBBox.size.height);
			CGContextAddLineToPoint(aContext, ((displayBBox.origin.x + displayBBox.size.width) - radius),
									displayBBox.origin.y + displayBBox.size.height);
			
		}
		
		// Acen disks
		
	} // for (acenPair)
	
	
    CGContextSetLineWidth(aContext, 2);
    [[UIColor blackColor] setStroke];
	CGContextStrokePath(aContext);

}
@end

