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
// Created by turner on 11/18/13.
//


#import "SEGRenderer.h"
#import "FeatureList.h"
#import "Feature.h"
#import "UIColor+Random.h"
#import "SEGFeature.h"
#import "Logging.h"
#import "FeatureTrackView.h"
#import "SEGCodec.h"
#import "SEGTrackView.h"
#import "SEGFeatureSource.h"
#import "FeatureInterval.h"
#import "FeatureRenderer.h"
#import "IGVContext.h"

// Rendering constants  TODO -- these should be user preferences
static CGFloat segMaxValue = 1.5;
static CGFloat segMinValue = -1.5;
static CGFloat segNeutralValue = 0.1;

@implementation SEGRenderer

- (void)renderInRect:(CGRect)rect sampleRows:(NSDictionary *)sampleRows sampleNames:(NSArray *)sampleNames {

    [[UIColor clearColor] setFill];

    UIRectFill(rect);

    CGRect renderSurface = [SEGTrackView renderSurfaceWithTrackRect:rect];


    [[UIColor colorWithWhite:.75 alpha:1] setFill];

    UIRectFill(renderSurface);

    CGFloat height = CGRectGetHeight(renderSurface) / ((CGFloat) [sampleNames count]);

    IGVContext *igvContext = [IGVContext sharedIGVContext];
    double pointsPerBase = (CGFloat) [igvContext pointsPerBase];

    FeatureInterval *currentFeatureInterval = [[IGVContext sharedIGVContext] currentFeatureInterval];

    [sampleNames enumerateObjectsUsingBlock:^(NSString *sampleName, NSUInteger sampleRowIndex, BOOL *ignoreOuter) {

        NSArray *sampleRow = [sampleRows objectForKey:sampleName];
        if (nil != sampleRow) {

            CGFloat minY = (sampleRowIndex * height) + CGRectGetMinY(renderSurface);
            CGRect sampleRowRect = CGRectMake(CGRectGetMinX(renderSurface), minY, CGRectGetWidth(renderSurface), height);

            [sampleRow enumerateObjectsUsingBlock:^(SEGFeature *segFeature, NSUInteger featureIndex, BOOL *ignoreInner) {

                if (segFeature.end < currentFeatureInterval.start || segFeature.start > currentFeatureInterval.end) {

                    // do nothing
                } else {
                    CGRect featureRect = [FeatureRenderer featureBounds:segFeature dataSurface:sampleRowRect pointsPerBase:pointsPerBase];

                    // Lay down white as backdrop for featureRect.
                    [[UIColor whiteColor] setFill];
                    UIRectFill(featureRect);

                    if (fabsf(segFeature.value) > segNeutralValue) {

                        UIColor *color = (segFeature.value < 0) ?
                                [UIColor colorWithRed:0 green:0 blue:1 alpha:segFeature.value / segMinValue] :
                                [UIColor colorWithRed:1 green:0 blue:0 alpha:segFeature.value / segMaxValue];

                        // porter-duff over color atop white
                        [color setFill];
                        UIRectFillUsingBlendMode(featureRect, kCGBlendModeNormal);
                    } else {

                        [[UIColor whiteColor] setFill];
                        UIRectFill(featureRect);
                    }
                }

            }];
        }

    }];

}

@end