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
//  Created by turner on 4/12/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "ExtendedFeatureRenderer.h"
#import "FeatureList.h"
#import "ExtendedFeature.h"
#import "Exon.h"
#import "IGVMath.h"
#import "FeatureInterval.h"
#import "Logging.h"
#import "TrackView.h"
#import "IGVContext.h"

@interface ExtendedFeatureRenderer ()

- (void)arrowHeadsAlongExtendedFeature:(ExtendedFeature *)aExtendedFeature context:(CGContextRef)aContext trackRect:(CGRect)trackRect color:(UIColor *)color pointsPerBase:(double)pointsPerBase featureInterval:(FeatureInterval *)featureInterval;

- (void)arrowHeadWithCenter:(CGPoint)center
        arrowHeadDimensions:(CGSize)arrowHeadDimensions
                     strand:(FeatureStrandType)strand
                      color:(UIColor *)color
                    context:(CGContextRef)context;
@end

@implementation ExtendedFeatureRenderer

- (void)renderInRect:(CGRect)rect featureList:(FeatureList *)featureList trackProperties:(NSDictionary *)trackProperties track:(TrackView *)track {

    if (nil == featureList) {
        return;
    }

    [self.labelBBoxList removeAllObjects];

    [[UIColor clearColor] setFill];
    UIRectFill(rect);

    [[UIColor whiteColor] setFill];
    CGRect renderSurface = [TrackView renderSurfaceWithTrackRect:rect];
    UIRectFill(renderSurface);

    [[UIColor whiteColor] setFill];
//    [[UIColor redColor] setFill];
    CGRect dataSurface = [TrackView dataSurfaceWithTrack:track];
    UIRectFill(dataSurface);

    CGContextSetLineWidth( UIGraphicsGetCurrentContext(), 2);

    IGVContext *igvContext = [IGVContext sharedIGVContext];

    double pointsPerBase = (CGFloat) [igvContext pointsPerBase];
    FeatureInterval *currentFeatureInterval = [igvContext currentFeatureInterval];

    for (ExtendedFeature *extendedFeature in featureList.features) {

        // east trivial rejection test: [feature start]
        if (extendedFeature.start > igvContext.end) {
            break; // We're done
        }
        // west trivial rejection test: [feature start] + [feature length]
        if ((extendedFeature.end) < igvContext.start) {
            continue;
        }

        CGRect featureSurface = [[self superclass] featureTileForFeature:extendedFeature
                                                             dataSurface:dataSurface
                                                              labelFrame:self.featureLabel.frame
                                                           pointsPerBase:pointsPerBase];

        UIColor *featureColor = (nil == extendedFeature.color) ? [LabeledFeatureRenderer lineColor] : extendedFeature.color;
        [featureColor setFill];

        if (nil == extendedFeature.exons) {

            // if we do not have exons draw featureSurface
            UIRectFill(featureSurface);
        } else {

            // if we have exons draw a line
            UIRectFill(CGRectInset(featureSurface, 0, (CGRectGetHeight(featureSurface)/2.0) * .95));
        }

        if (nil != extendedFeature.exons) {

            [self arrowHeadsAlongExtendedFeature:extendedFeature
                                         context: UIGraphicsGetCurrentContext()
                                       trackRect:featureSurface
                                           color:[LabeledFeatureRenderer arrowHeadColor]
                                   pointsPerBase:pointsPerBase
                                 featureInterval:currentFeatureInterval];

            [[FeatureRenderer tileColor] setFill];
            for (Exon *exon in extendedFeature.exons) {
                UIRectFill([exon featureTileForFeatureSurface:featureSurface pointsPerBase:pointsPerBase]);
            }
        }

        [self featureLabelWithLabelTemplate:self.featureLabel
                             featureSurface:featureSurface
                                    feature:extendedFeature
                                labelBBoxes:self.labelBBoxList];
    }

}

- (void)arrowHeadsAlongExtendedFeature:(ExtendedFeature *)aExtendedFeature
                               context:(CGContextRef)aContext
                             trackRect:(CGRect)trackRect
                                 color:(UIColor *)color
                         pointsPerBase:(double)pointsPerBase
                       featureInterval:(FeatureInterval *)featureInterval {


    // arrow heads indicate strand direction. No strand, no render.
    if (FeatureStrandTypeNone == aExtendedFeature.strand) {
        return;
    }

    const CGFloat arrowHeadSpacer_p = 100.0;

    long long start_b = MAX(aExtendedFeature.start, featureInterval.start) - featureInterval.start;
    long long   end_b = MIN(aExtendedFeature.end,   featureInterval.end  ) - featureInterval.start;

    double start_p = pointsPerBase * ((CGFloat) start_b);
    double   end_p = pointsPerBase * ((CGFloat) end_b);

    CGFloat dimen = CGRectGetHeight(trackRect);
    while ((start_p + arrowHeadSpacer_p) < end_p) {

        start_p += arrowHeadSpacer_p;

        [self arrowHeadWithCenter:CGPointMake((CGFloat)start_p, CGRectGetMidY(trackRect))
              arrowHeadDimensions:CGSizeMake(dimen/3.0, dimen/2.0)
                           strand:aExtendedFeature.strand
                            color:color
                          context:aContext];
    }

}

- (void)arrowHeadWithCenter:(CGPoint)center
        arrowHeadDimensions:(CGSize)arrowHeadDimensions
                     strand:(FeatureStrandType)strand
                      color:(UIColor *)color
                    context:(CGContextRef)context {

    //
    // In Photoshop parlence
    // w - width of base of arrowhead triangle
    // h - length from arrowhead triangle base to point
    // photoShopArrowhead = CGSizeMake(w, h);
    //

    CGRect arrowHeadBBox = [IGVMath rectWithCenter:center size:CGSizeMake(arrowHeadDimensions.height, arrowHeadDimensions.width)];

    float x = (FeatureStrandTypeNegative == strand) ? CGRectGetMaxX(arrowHeadBBox) : CGRectGetMinX(arrowHeadBBox);
    float y = CGRectGetMinY(arrowHeadBBox);

    float dx = (FeatureStrandTypeNegative == strand) ? -arrowHeadDimensions.height : arrowHeadDimensions.height;


//    UIColor *arrowheadDebugColor = (FeatureStrandNegative == strand) ? [UIColor redColor] : [UIColor blueColor];
//    CGContextSetBlendMode (context, kCGBlendModeNormal);

    [[UIColor grayColor] setStroke];
//    [arrowheadDebugColor setFill];

    CGContextSetLineWidth(context, 1);

    CGContextBeginPath(context);

    CGContextMoveToPoint(context, x, y);
    CGContextAddLineToPoint(context, x + dx, y + arrowHeadDimensions.width / 2);
    CGContextAddLineToPoint(context, x, y + arrowHeadDimensions.width);

    CGContextStrokePath(context);

}

@end