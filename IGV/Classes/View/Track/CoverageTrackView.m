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
//  CoverageTrack.m
//  IGV
//
//  Created by Douglass Turner on 1/18/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "CoverageTrackView.h"
#import "CoverageRenderer.h"
#import "AlignmentResults.h"
#import "Coverage.h"
#import "TrackDelegate.h"
#import "Logging.h"
#import "RefSeqFeatureList.h"
#import "FeatureInterval.h"
#import "RefSeqTrackView.h"
#import "UIApplication+IGVApplication.h"
#import "EraseRenderer.h"
#import "IGVHelpful.h"
#import "AlignmentRow.h"
#import "AlignmentTrackView.h"
#import "EraseRenderer.h"

@interface CoverageTrackView ()
@property(nonatomic, retain) id renderer;
@property(nonatomic, retain) EraseRenderer *eraseRenderer;
@end

@implementation CoverageTrackView

@synthesize alignmentResults = _alignmentResults;

#pragma mark -
#pragma mark CoverageTrack Lifecycle Methods

- (void)dealloc {

    self.alignmentResults = nil;
    self.renderer = nil;
    self.eraseRenderer = nil;
    [super dealloc];
}

- (void)initializationHelper {

    [super initializationHelper];

    self.renderer = [[[CoverageRenderer alloc] init] autorelease];
    self.eraseRenderer = [[[EraseRenderer alloc] initWithEraseColor:[UIColor whiteColor]] autorelease];

}


- (void)drawRect:(CGRect)rect {

    if (nil == self.alignmentResults || nil == self.alignmentResults.coverage.coverageList) {

        [self.eraseRenderer renderInRect:rect featureList:nil trackProperties:nil track:nil];
    } else {

        [self.renderer renderInRect:rect track:self];

    }

}

+ (CGFloat)trackHeight {
    return 40;
}
@end
