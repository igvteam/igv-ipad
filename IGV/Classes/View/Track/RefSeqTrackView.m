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
//  ReferenceSequenceTrack.m
//  HelloSequence
//
//  Created by turner on 9/27/09.
//  Copyright 2009 Douglass Turner Consulting. All rights reserved.
//

#import "RefSeqTrackView.h"
#import "RefSeqTrackController.h"
#import "RefSeqRenderer.h"
#import "ReferenceSequenceNullRenderer.h"
#import "RefSeqFeatureList.h"
#import "Logging.h"
#import "IGVHelpful.h"
#import "EraseRenderer.h"
#import "IGVContext.h"
#import "FeatureInterval.h"
#import "AlignmentTrackView.h"
#import "RefSeqFeatureSource.h"

@interface RefSeqTrackView ()
@property(nonatomic, retain) ReferenceSequenceNullRenderer *nullRenderer;
@property(nonatomic, retain) EraseRenderer *eraseRenderer;
@end

@implementation RefSeqTrackView

@synthesize featureSource;
@synthesize featureList;

- (void)dealloc {

    self.featureSource = nil;
    self.featureList = nil;
    self.nullRenderer = nil;
    self.eraseRenderer = nil;
    [super dealloc];
}

- (void)initializationHelper {

    [super initializationHelper];

    self.renderer = [[[RefSeqRenderer alloc] init] autorelease];
    self.nullRenderer = [[[ReferenceSequenceNullRenderer alloc] initWithBackdropColor:[UIColor colorWithWhite:0.75 alpha:1.0] lineColor:[UIColor colorWithWhite:0.25 alpha:1.0]] autorelease];
    self.eraseRenderer = [[[EraseRenderer alloc] initWithEraseColor:[UIColor whiteColor]] autorelease];
}

- (void)drawRect:(CGRect)rect {

    FeatureInterval *currentInterval = [[IGVContext sharedIGVContext] currentFeatureInterval];

    if (nil == self.featureSource || nil == currentInterval) {

        [super drawRect:rect];
        return;
    }

    if ([AlignmentTrackView isBelowFeatureRenderingThreshold]) {

        [self.eraseRenderer renderInRect:rect featureList:nil trackProperties:nil track:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:TrackDidFinishRenderingNotification object:self];
        return;
    }

    if ([self.featureSource hasSequenceForInterval:currentInterval]) {

        [self.renderer renderInRect:rect featureList:self.featureList trackProperties:nil track:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:TrackDidFinishRenderingNotification object:self];
    } else {

        [self.featureSource loadFeaturesForInterval:currentInterval completion:^() {

            dispatch_async(dispatch_get_main_queue(), ^{
                [self setNeedsDisplay];
            });

        }];
    }
}

- (NSString *)refSeqLetterWithRefSeqStringIndex:(NSInteger)refSeqStringIndex {

    RefSeqFeatureList *refSeqFeatureList = self.featureList;

    if (refSeqStringIndex < 0 || refSeqStringIndex >= [refSeqFeatureList.refSeqString length]) {
        ALog(@"ERROR: refSeqStringIndex %d out of bounds for refSeqString %d", refSeqStringIndex, [refSeqFeatureList.refSeqString length]);
        return nil;
    }
    return [NSString stringWithUnichar:[refSeqFeatureList.refSeqString characterAtIndex:(NSUInteger) refSeqStringIndex]];
}

@end
