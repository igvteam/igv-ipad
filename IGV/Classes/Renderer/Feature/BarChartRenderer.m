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
// Created by turner on 5/14/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "BarChartRenderer.h"
#import "WIGFeature.h"
#import "FeatureList.h"
#import "DataScale.h"
#import "FeatureSourceUtils.h"
#import "FeatureInterval.h"
#import "FeatureTrackView.h"
#import "IGVContext.h"
#import "IGVMath.h"
#import "Logging.h"

@interface BarChartRenderer ()
@end

@implementation BarChartRenderer

- (void)renderInRect:(CGRect)rect featureList:(FeatureList *)featureList trackProperties:(NSDictionary *)trackProperties track:(TrackView *)track {

    [[UIColor clearColor] setFill];
    UIRectFill(rect);

    [[UIColor whiteColor] setFill];
    CGRect renderSurface = [TrackView renderSurfaceWithTrackRect:rect];
    UIRectFill(renderSurface);

    [[UIColor whiteColor] setFill];
    CGRect dataSurface = [TrackView dataSurfaceWithTrack:track];
    UIRectFill(dataSurface);

    if (nil == featureList) {
        return;
    }

    // trivially reject a score outside the dataScale extent.
    FeatureTrackView *featureTrack = (FeatureTrackView *)track;
    if (!featureTrack.doWigFeatureAutoDataScale && [featureTrack.wigFeatureDataScale trivialRejectFeatureList:featureList]) {
        return;
    }

    UIColor *color = [trackProperties objectForKey:@"color"];
    if (nil == color) {
        color = [[self class] tileColor];
    }
    [color setFill];

    // Find start/end indices for visible features.  Linear search for now, binary would be faster.
    FeatureInterval *currentFeatureInterval = [[IGVContext sharedIGVContext] currentFeatureInterval];
    NSInteger startIndex;
    NSInteger endIndex;
    [Renderer calculateStartIndex:&startIndex
                         endIndex:&endIndex
                      featureList:featureList
           currentFeatureInterval:currentFeatureInterval];

    NSArray *collapsedFeatures = [FeatureSourceUtils collapseFeatures:featureList.features
                                                           startIndex:startIndex
                                                             endIndex:endIndex];


    CGFloat yBaselinePoints = [featureTrack.wigFeatureDataScale yBaselinePointsWithRenderSurface:dataSurface];

    CGFloat pointsPerBase = (CGFloat) [[IGVContext sharedIGVContext] pointsPerBase];
    for (WIGFeature *wigFeature in collapsedFeatures) {

        CGFloat xmin = ((CGFloat) (wigFeature.start - currentFeatureInterval.start) * pointsPerBase);
        CGFloat xmax = ((CGFloat) (wigFeature.end   - currentFeatureInterval.start) * pointsPerBase);
        CGFloat width = MAX(1,  xmax - xmin);

        CGFloat score = wigFeature.score;

        if (!featureTrack.doWigFeatureAutoDataScale) {
            score = [featureTrack.wigFeatureDataScale clipValue:wigFeature.score nonNegativeDataSet:[featureList isNonNegativeDataSet]];
        }

        CGFloat height = fabsf(score) * CGRectGetHeight(dataSurface) / [featureTrack.wigFeatureDataScale range];
        CGFloat ymin = (score < 0) ? yBaselinePoints : yBaselinePoints - height;

        // clamp
        ymin = MAX(CGRectGetMinY(dataSurface), ymin);
        height = MIN(CGRectGetMaxY(dataSurface) - ymin, height);

        // render
        UIRectFill(CGRectMake(xmin, ymin, width, height));
    }

    // Draw a line through the base => normalizedScore == 0 deletion
    [[UIColor colorWithRed:180 green:180 blue:180 alpha:0.9] setFill];
    UIRectFill(CGRectMake(CGRectGetMinX(dataSurface), yBaselinePoints, CGRectGetWidth(dataSurface), 1));

}

@end

