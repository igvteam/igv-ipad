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


#import "FeatureRenderer.h"
#import "FeatureList.h"
#import "Feature.h"
#import "Logging.h"
#import "UIColor+Random.h"
#import "TrackView.h"
#import "IGVContext.h"

@implementation FeatureRenderer

- (void)renderInRect:(CGRect)rect featureList:(FeatureList *)featureList trackProperties:(NSDictionary *)trackProperties track:(TrackView *)track {

    [[UIColor clearColor] setFill];
    UIRectFill(rect);

    CGRect renderSurface = [TrackView renderSurfaceWithTrackRect:rect];

    [[UIColor whiteColor] setFill];
    UIRectFill(renderSurface);

    if (nil == featureList) {
        return;
    }

    [[[self class] tileColor] setFill];

    IGVContext *igvContext = [IGVContext sharedIGVContext];
    double pointsPerBase = (CGFloat)[igvContext pointsPerBase];

    [featureList.features enumerateObjectsUsingBlock:^(Feature *feature, NSUInteger index, BOOL *stop){

        if (feature.end >= igvContext.start && feature.start <= igvContext.end) {

            ALog(@"%@", feature);
            [[UIColor randomRGBWithAlpha:0.75] setFill];
            CGRect tile = [[self class] featureBounds:feature dataSurface:renderSurface pointsPerBase:pointsPerBase];
            UIRectFillUsingBlendMode(tile, kCGBlendModeNormal);

        }

    } ];

}

+ (CGRect)featureBounds:(Feature *)feature dataSurface:(CGRect)dataSurface pointsPerBase:(double)pointsPerBase {

    double x = feature.start - [IGVContext sharedIGVContext].start;
    x *= pointsPerBase;

    double width = [feature length];
    width *= pointsPerBase;

    if (width < 1.0) {
        x = floor(x);
        width = 1.0;
    }

    return CGRectMake((CGFloat)x, CGRectGetMinY(dataSurface), (CGFloat)width, CGRectGetHeight(dataSurface));;
}

+ (UIColor *)tileColor {

    // IGV Desktop blue
    return [UIColor colorWithRed:0 green:0 blue:150.0/255.0 alpha:1.0];
}

@end