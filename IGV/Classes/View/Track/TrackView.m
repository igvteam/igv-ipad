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
//  Track.m
//  IGV
//
//  Created by Douglass Turner on 3/2/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "TrackView.h"
#import "RefSeqTrackController.h"
#import "Renderer.h"
#import "Logging.h"
#import "UINib-View.h"
#import "UILabel+TrackView.h"
#import "IGVMath.h"
#import "LMResource.h"
#import "TrackContainerScrollView.h"
#import "UIApplication+IGVApplication.h"
#import "TrackDelegate.h"

//CGFloat const kRenderSurfaceInsetPercentage = 0.125;
CGFloat const kRenderSurfaceInsetPercentage = 0.100/2.0;
CGFloat const kTrackLabelXShim = 8.0;

@implementation TrackView

@synthesize trackLabel;
@synthesize resource = _resource;
@synthesize trackDelegate = _trackDelegate;
@synthesize isSquished = _isSquished;
@synthesize renderer = _renderer;

- (void)dealloc {

    self.renderer = nil;
    self.trackLabel = nil;
    self.resource = nil;
    self.trackDelegate = nil;

    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame {

    self = [super initWithFrame:frame];

    if (nil != self) {

        [self initializationHelper];
    }

    return self;
}

- (id)initWithFrame:(CGRect)frame resource:(LMResource *)resource trackDelegate:(TrackDelegate *)trackDelegate {

    self = [super initWithFrame:frame];

    if (nil != self) {

        self.resource = resource;
        self.trackDelegate = trackDelegate;
        self.trackDelegate.track = self;

        [self initializationHelper];
    }

    return self;
}

- (void)awakeFromNib {
    [self initializationHelper];
}

- (void)initializationHelper {
    self.isSquished = NO;
    self.backgroundColor = [UIColor clearColor];
}

- (NSArray *)popupMenuItemTitles {
    ALog(@"%@ does not implement this method.", [self class]);
    return nil;
}

- (CGRect)trackLabelFrameWithScrollViewContentOffset:(CGPoint)contentOffset trackLabelFrame:(CGRect)trackLabelFrame {

    trackLabelFrame.origin.x = kTrackLabelXShim + contentOffset.x;
    return trackLabelFrame;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
}

- (UILabel *)trackLabelWithText:(NSString *)text {

    UILabel *label = (UILabel *) [UINib containerViewForNibNamed:@"TrackLabel"];

    label.text = text;

    [label sizeToFit];

    [label layoutTrackLabelWithRenderSurface:[[self class] renderSurfaceWithTrackRect:self.bounds]];

    return label;
}

- (void)sortFeaturesWithLocation:(long long int)location {
    ALog(@"%@ does not implement this method.", [self class]);
}

- (CGFloat)squishedTrackHeight {
    ALog(@"%@ does not implement this method. Returning 0", [self class]);
    return 0;
}

- (CGFloat)expandedTrackHeight {
    ALog(@"%@ does not implement this method. Returning 0", [self class]);
    return 0;
}

+ (CGFloat)trackHeight {
    ALog(@"%@ does not implement this method. Returning 0", [self class]);
    return 0;
}

+ (CGFloat)renderSurfaceInsetShimWithTrackRectHeight:(CGFloat)trackRectHeight {
    return [TrackView renderSurfaceInsetPercentage] * trackRectHeight;
}

+ (CGRect)renderSurfaceWithTrackRect:(CGRect)trackRect {

    CGFloat shimHeight = 60;
    CGRect renderSurface = CGRectInset(trackRect, 0, [TrackView renderSurfaceInsetShimWithTrackRectHeight:shimHeight]);
    return renderSurface;
}

+ (CGFloat)renderSurfaceInsetPercentage {
    return kRenderSurfaceInsetPercentage;
}

+ (CGRect)dataSurfaceWithTrack:(TrackView *)track {

    UILabel *label = [track trackLabelWithText:@"nuthin"];

    CGRect renderSurface = [TrackView renderSurfaceWithTrackRect:track.bounds];

    CGPoint origin = CGPointMake(CGRectGetMinX(renderSurface), CGRectGetMaxY(label.frame));
    CGSize size = CGSizeMake(CGRectGetWidth(renderSurface), CGRectGetHeight(renderSurface) - CGRectGetHeight(label.bounds));

    return [IGVMath rectWithOrigin:origin size:size];
}

+ (CGRect)trackFrame {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    CGRect frame = CGRectMake(0, 0, CGRectGetWidth(rootContentController.trackContainerScrollView.bounds), [self trackHeight]);

    return frame;
}

- (NSString *)description {

    NSString *string = (nil == self.trackLabel) ? @"unnamed" : self.trackLabel.text;
    return [NSString stringWithFormat:@"%@ %@", [self class], string];
}


@end
