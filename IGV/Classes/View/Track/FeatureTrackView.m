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
//  FeatureTrack.m
//  IGV
//
//  Created by Douglass Turner on 3/2/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "FeatureTrackView.h"
#import "TrackContainerScrollView.h"
#import "Renderer.h"
#import "FeatureRenderer.h"
#import "LabeledFeatureRenderer.h"
#import "ExtendedFeatureRenderer.h"
#import "LabeledFeature.h"
#import "ExtendedFeature.h"
#import "FeatureList.h"
#import "FeatureInterval.h"
#import "DataScale.h"
#import "BarChartRenderer.h"
#import "EraseRenderer.h"
#import "WIGFeature.h"
#import "UIApplication+IGVApplication.h"
#import "LMResource.h"
#import "EncodePeakFeature.h"
#import "Logging.h"
#import "RootContentController.h"
#import "IGVContext.h"
#import "LocusListItem.h"
#import "UINib-View.h"

@interface FeatureTrackView ()
@property(nonatomic, retain) EraseRenderer *eraseRenderer;
@property(nonatomic, retain) NSMutableDictionary *renderers;
@end

@implementation FeatureTrackView
#pragma mark -
#pragma mark FeatureTrackView Lifecycle Methods

@synthesize featureSource;
@synthesize renderers;
@synthesize wigFeatureDataScale = _wigFeatureDataScale;
@synthesize doWigFeatureAutoDataScale = _doWigFeatureAutoDataScale;

- (void)dealloc {

    self.featureSource = nil;
    self.renderers = nil;
    self.eraseRenderer = nil;
    self.wigFeatureDataScale = nil;

    [super dealloc];
}

- (void)initializationHelper {

    [super initializationHelper];

    self.doWigFeatureAutoDataScale = NO;

    self.renderers = [NSMutableDictionary dictionary];
    [self.renderers setObject:[[[LabeledFeatureRenderer alloc] init] autorelease] forKey:NSStringFromClass([LabeledFeature class])];
    [self.renderers setObject:[[[ExtendedFeatureRenderer alloc] init] autorelease] forKey:NSStringFromClass([ExtendedFeature class])];
    [self.renderers setObject:[[[ExtendedFeatureRenderer alloc] init] autorelease] forKey:NSStringFromClass([EncodePeakFeature class])];
    [self.renderers setObject:[[[BarChartRenderer alloc] init] autorelease] forKey:NSStringFromClass([WIGFeature class])];

    self.eraseRenderer = [[[EraseRenderer alloc] initWithEraseColor:[UIColor whiteColor]] autorelease];


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

- (void)drawRect:(CGRect)rect {

    if (nil == self.featureSource) {
        [super drawRect:rect];
    }

    else if ([[IGVContext sharedIGVContext] currentLocusListItem].length > self.featureSource.visibilityWindowThreshold) {

        [self renderZoomedOutView:rect];
        [[NSNotificationCenter defaultCenter] postNotificationName:TrackDidFinishRenderingNotification object:self];

    }
    else {

        FeatureInterval *currentFeatureInterval = [[IGVContext sharedIGVContext] currentFeatureInterval];

        FeatureList *featureList = [self.featureSource featuresForFeatureInterval:currentFeatureInterval];

        if (nil == featureList) {

            [self.featureSource loadFeaturesForInterval:currentFeatureInterval completion:^() {

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setNeedsDisplay];
                });

            }];
        } else {

            self.renderer = (0 == [featureList.features count]) ?
                    self.eraseRenderer :
                    [self.renderers objectForKey:[featureList stringFromFeatureClass]];


            if ([[featureList stringFromFeatureClass] isEqualToString:NSStringFromClass([WIGFeature class])]) {
                [self updateDataScale:featureList];
            }

            [self.renderer renderInRect:rect featureList:featureList trackProperties:self.featureSource.trackProperties track:self];
            [[NSNotificationCenter defaultCenter] postNotificationName:TrackDidFinishRenderingNotification object:self];

        }

    }

}

- (void)updateDataScale:(FeatureList *)featureList {
    if (self.doWigFeatureAutoDataScale) {

        // Calculate dataScale anew for each render invocation
        self.wigFeatureDataScale = [DataScale dataScaleWithMin:featureList.minScore max:featureList.maxScore];
    } else {

        if (nil == self.wigFeatureDataScale) {

            self.wigFeatureDataScale = [self.featureSource.trackProperties objectForKey:@"viewLimits"];

            if (nil == self.wigFeatureDataScale) {
                self.wigFeatureDataScale = [DataScale dataScaleWithMin:featureList.minScore max:featureList.maxScore];
            }
        }

    }
}

- (void)renderZoomedOutView:(CGRect)rect {
    [[UIColor whiteColor] setFill];
    UIRectFill(rect);

    UILabel *label = (UILabel *) [UINib containerViewForNibNamed:@"ZoomLevelInToSeeFeatures"];

    CGFloat y = CGRectGetMinY(rect) + CGRectGetMidY(label.bounds);
    CGFloat x = CGRectGetMinX(rect);
    CGRect bbox = [label bounds];

    CGSize letterSize = [label.text sizeWithFont:label.font];
//        CGSize letterSize = [label.text sizeWithAttributes:[NSDictionary dictionaryWithObject:label.font forKey:NSFontAttributeName]];


    CGFloat xInset = (CGRectGetWidth(bbox) - letterSize.width) / 2.0;
    CGFloat yInset = (CGRectGetHeight(bbox) - letterSize.height) / 2.0;

    const CGFloat nudge = 0.8;
    yInset /= nudge;

    while (x < CGRectGetMaxX(rect)) {

        bbox.origin = CGPointMake(x, y);
        [label.textColor setFill];

        [label.text drawInRect:CGRectInset(bbox, xInset, yInset) withFont:label.font];
//            [label.text drawInRect:CGRectInset(bbox, xInset, yInset) withAttributes:[NSDictionary dictionaryWithObject:label.font forKey:NSFontAttributeName]];

        x += 1.5 * CGRectGetWidth(bbox);
    }
}

+ (CGFloat)trackHeight {
    return 60;
}
@end
