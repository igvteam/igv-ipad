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
//  AlignmentTrackRenderer.m
//  IGV
//
//  Created by Douglass Turner on 3/21/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "AlignmentRenderer.h"
#import "AlignmentBlock.h"
#import "AlignmentTrackView.h"
#import "AlignmentRow.h"
#import "RefSeqTrackView.h"
#import "FeatureList.h"
#import "UINib-View.h"
#import "RefSeqFeatureList.h"
#import "CoverageTrackView.h"
#import "Logging.h"
#import "RefSeqRenderer.h"
#import "RefSeqFeatureSource.h"
#import "UIApplication+IGVApplication.h"
#import "FeatureInterval.h"
#import "AlignmentResults.h"
#import "TrackDelegate.h"
#import "RootContentController.h"
#import "IGVContext.h"

@interface AlignmentRenderer ()
+ (void)renderMismatchWithFeatureSurface:(CGRect)featureSurface nucleotideLetterLabel:(UILabel *)nucleotideLetterLabel quality:(u_int8_t)quality;
+ (void)renderMismatchLetterWithFeatureSurface:(CGRect)featureSurface nucleotide:(UILabel *)nucleotide quality:(u_int8_t)quality;

- (void)renderAlignmentBlock:(AlignmentBlock *)alignmentBlock backdrop:(CGRect)backdrop color:(UIColor *)color pointPerBases:(CGFloat)pointPerBases featureIntervalStart:(long long int)featureIntervalStart;
- (void)renderArrowHeadWithAlignmentBBox:(CGRect)alignmentBBox strand:(BOOL)strand color:(UIColor *)color;
+ (void)renderZoomInAnnouncementWithRenderSurface:(CGRect)renderSurface;
+ (void)renderZeroQualityAlignment:(Alignment *)alignment alignmentBounds:(CGRect)alignmentBounds;
+ (void)renderArrowHeadWithAlignment:(Alignment *)alignment fillColor:(UIColor *)fillColor strokeColor:(UIColor *)strokeColor alignmentBounds:(CGRect)alignmentBounds;
+ (void)renderGapWithAlignmentBounds:(CGRect)alignmentBounds alignmentGapLineStyle:(char)alignmentGapLineStyle;
@end

@implementation AlignmentRenderer

- (void)dealloc {

    [super dealloc];
}

- (void)renderInRect:(CGRect)rect featureList:(FeatureList *)featureList trackProperties:(NSDictionary *)trackProperties track:(TrackView *)track {

    [[UIColor clearColor] setFill];
    UIRectFill(rect);

    [[UIColor whiteColor] setFill];
    CGRect renderSurface = [AlignmentTrackView renderSurfaceWithTrackRect:rect];
    UIRectFill(renderSurface);

    if ([AlignmentTrackView isBelowFeatureRenderingThreshold]) {

        UILabel *label = (UILabel *) [UINib containerViewForNibNamed:@"ZoomLevelInToSeeAlignments"];

        CGFloat y = CGRectGetMinY(renderSurface) + CGRectGetMidY(label.bounds);
        CGFloat x = CGRectGetMinX(renderSurface);
        CGRect bbox = [label bounds];

        CGSize letterSize = [label.text sizeWithFont:label.font];
//        CGSize letterSize = [label.text sizeWithAttributes:[NSDictionary dictionaryWithObject:label.font forKey:NSFontAttributeName]];


        CGFloat xInset = (CGRectGetWidth( bbox) - letterSize.width )/2.0;
        CGFloat yInset = (CGRectGetHeight(bbox) - letterSize.height)/2.0;

        const CGFloat nudge = 0.8;
        yInset /= nudge;

        while (x < CGRectGetMaxX(renderSurface)) {

            bbox.origin = CGPointMake(x, y);
            [label.textColor setFill];

            [label.text drawInRect:CGRectInset(bbox, xInset, yInset) withFont:label.font];
//            [label.text drawInRect:CGRectInset(bbox, xInset, yInset) withAttributes:[NSDictionary dictionaryWithObject:label.font forKey:NSFontAttributeName]];


            x += 1.5 * CGRectGetWidth(bbox);
        }

        return;
    }

    if (nil == featureList) {
        return;
    }

    [[[AlignmentTrackView alignmentColors] objectForKey:@"dark"] setStroke];
    CGContextSetLineWidth( UIGraphicsGetCurrentContext(), 2.0 / 3.0);
    AlignmentTrackView *alignmentTrack = (AlignmentTrackView *)track;
    float wye = CGRectGetMaxY(alignmentTrack.coverageTrack.frame);
    CGRect alignmentReadTemplate = CGRectMake(0, 0, 1, [alignmentTrack alignmentReadTemplateHeight]);

    IGVContext *igvContext = [IGVContext sharedIGVContext];
    RefSeqFeatureSource *refSeqFeatureSource = [UIApplication sharedRootContentController].refSeqTrack.featureSource;
    FeatureInterval *currentInterval = [[IGVContext sharedIGVContext] currentFeatureInterval];

    CGFloat pointsPerBase = (CGFloat) [igvContext pointsPerBase];
    for (AlignmentRow *alignmentRow in featureList.features) {

        for (Alignment *alignment in alignmentRow.alignments) {

            if (alignment.end < currentInterval.start) {
                continue;
            } else if (alignment.start > currentInterval.end) {
                continue;
            }

            if ([alignment unmapped]) {
                continue;
            }

            CGFloat exe   = pointsPerBase * ((CGFloat)(alignment.start - currentInterval.start));
            CGFloat width = pointsPerBase * ((CGFloat)[alignment length]);

            CGRect alignmentBounds = alignmentReadTemplate;
            alignmentBounds.origin = CGPointMake(exe, wye);
            alignmentBounds.size.width = width;

            if (0 == alignment.quality) {
                [AlignmentRenderer renderZeroQualityAlignment:alignment alignmentBounds:alignmentBounds];
                continue;
            }

            [AlignmentRenderer renderGapWithAlignmentBounds:alignmentBounds alignmentGapLineStyle:alignment.gapLineStyle];

            CGRect alignmentRenderQuad = CGRectInset(alignmentBounds, 0, 1);

            [self renderArrowHeadWithAlignmentBBox:alignmentRenderQuad
                                            strand:alignment.negativeStrand
                                             color:[[AlignmentTrackView alignmentColors] objectForKey:@"grey_light"]];

            [[[AlignmentTrackView alignmentColors] objectForKey:@"grey_light"] setFill];

            for (AlignmentBlock *alignmentBlock in alignment.alignmentBlocks) {

                if ([alignmentBlock end] < currentInterval.start || alignmentBlock.start > currentInterval.end) {
                    continue;
                }

                if (1 > alignmentBlock.length) {
                    continue;
                }

                [self renderAlignmentBlock:alignmentBlock
                                  backdrop:alignmentRenderQuad
                                     color:[[AlignmentTrackView alignmentColors] objectForKey:@"grey_light"]
                             pointPerBases:pointsPerBase
                      featureIntervalStart:currentInterval.start];

                if (![refSeqFeatureSource referenceSequenceStringExists]) {
                    continue;
                }

                int alignmentBlockIndex;
                long long int genomicLocation;
                for (alignmentBlockIndex = 0,  genomicLocation = alignmentBlock.start;
                     alignmentBlockIndex < alignmentBlock.length;
                     alignmentBlockIndex++, genomicLocation++) {

                    CGRect alignmentBlockTile = CGRectMake(pointsPerBase * (genomicLocation - currentInterval.start), CGRectGetMinY(alignmentRenderQuad), pointsPerBase, CGRectGetHeight(alignmentRenderQuad));

                    char letter = (char)[refSeqFeatureSource refSeqCharWithGenomicLocation:genomicLocation];

                    if (0 == letter) {
                        continue;
                    }

                    if ([alignmentBlock bases][alignmentBlockIndex] != letter) {

                        // Look up the nucleotideLetterLabel letter, color, and font
                        UILabel *nucleotideLetterLabel = [igvContext.nucleotideLetterLabels objectForKey:[NSString stringWithFormat:@"%c", [alignmentBlock bases][alignmentBlockIndex]]];

                        if ([AlignmentRenderer colorExistsWithNucleotide:nucleotideLetterLabel]) {

                            [AlignmentRenderer renderMismatchWithFeatureSurface:alignmentBlockTile
                                                          nucleotideLetterLabel:nucleotideLetterLabel
                                                                        quality:[alignmentBlock qualities][alignmentBlockIndex]];

                            // TODO - design nucleotideLetterLabel letters that are shorter the the current letter
//                            if (YES == alignmentTrack.isSquished || pointsPerBase < kNucleotideLetterRenderThreshold) {
//                                [AlignmentRenderer renderMismatchWithFeatureSurface:alignmentBlockTile
//                                                                         nucleotideLetterLabel:nucleotideLetterLabel
//                                                                            quality:[alignmentBlock qualities][alignmentBlockIndex]];
//
//                            } else {
//
//                                [AlignmentRenderer renderMismatchLetterWithFeatureSurface:alignmentBlockTile
//                                                                               nucleotideLetterLabel:nucleotideLetterLabel
//                                                                                  quality:[alignmentBlock qualities][alignmentBlockIndex]];
//
//                            }

                        }
                    }

//                    if (alignmentRow.alignmentBlockItem && alignmentBlock == [alignmentRow.alignmentBlockItem objectForKey:@"block"]) {
//
//                        if (alignmentBlockIndex == [[alignmentRow.alignmentBlockItem objectForKey:@"index"] integerValue]) {
//
//                            UILabel *nucleotideLetterLabel = [igvContext.nucleotideLetterLabels objectForKey:[NSString stringWithFormat:@"%c", [alignmentBlock bases][alignmentBlockIndex]]];
//                            [AlignmentRenderer renderNucleotideLetterWithFeatureSurface:alignmentBlockTile nucleotideLetterLabel:nucleotideLetterLabel];
//                        }
//
//                    }

                }

            }

//            // Potential deletion
//            [[UIColor darkGrayColor] setFill];
//            UIRectFill(CGRectInset(_rect, 0, (_rect.size.height - 2) / 2));

        }

        wye += CGRectGetHeight(alignmentReadTemplate);
    }

}

+ (void)renderNucleotideLetterWithFeatureSurface:(CGRect)featureSurface nucleotideLetterLabel:(UILabel *)nucleotideLetterLabel {

    [nucleotideLetterLabel.textColor setFill];
    UIRectFill(featureSurface);

//    CGSize letterSize = [nucleotideLetterLabel.text sizeWithFont:nucleotideLetterLabel.font];
    CGSize letterSize = [nucleotideLetterLabel.text sizeWithAttributes:[NSDictionary dictionaryWithObject:nucleotideLetterLabel.font forKey:NSFontAttributeName]];
    CGFloat shim = (CGRectGetWidth(featureSurface) - letterSize.width)/2.0;

    [[UIColor whiteColor] setFill];
//    [nucleotideLetterLabel.text drawInRect:CGRectInset(featureSurface, shim, 0) withFont:nucleotideLetterLabel.font];
    [nucleotideLetterLabel.text drawInRect:CGRectInset(featureSurface, shim, 0) withAttributes:[NSDictionary dictionaryWithObject:nucleotideLetterLabel.font forKey:NSFontAttributeName]];



}

+ (BOOL)colorExistsWithNucleotide:(UILabel *)nucleotide {

    const CGFloat *rgba = CGColorGetComponents(nucleotide.textColor.CGColor);
    return nil != rgba;
}

+ (void)renderMismatchWithFeatureSurface:(CGRect)featureSurface
                   nucleotideLetterLabel:(UILabel *)nucleotideLetterLabel
                                 quality:(u_int8_t)quality {

    [[UIColor whiteColor] setFill];
    UIRectFill(featureSurface);

    const CGFloat *rgba = CGColorGetComponents(nucleotideLetterLabel.textColor.CGColor);

    [[UIColor colorWithRed:rgba[0] green:rgba[1] blue:rgba[2] alpha:[Alignment alphaFromQuality:quality]] setFill];

    UIRectFillUsingBlendMode(featureSurface, kCGBlendModeNormal);
}

+ (void)renderMismatchLetterWithFeatureSurface:(CGRect)featureSurface
                                    nucleotide:(UILabel *)nucleotide
                                       quality:(u_int8_t)quality {

    [[UIColor whiteColor] setFill];
    UIRectFill(featureSurface);

    // solid color - nucleotide letter color
//    [nucleotide.textColor setFill];
//    UIRectFill(featureSurface);

    // translucent color - quality as alpha to change opacity of nucleotide letter color
    const CGFloat *rgba = CGColorGetComponents(nucleotide.textColor.CGColor);
    [[UIColor colorWithRed:rgba[0] green:rgba[1] blue:rgba[2] alpha:[Alignment alphaFromQuality:quality]] setFill];
    UIRectFillUsingBlendMode(featureSurface, kCGBlendModeNormal);

//    CGSize letterSize = [nucleotide.text sizeWithFont:nucleotide.font];
    CGSize letterSize = [nucleotide.text sizeWithAttributes:[NSDictionary dictionaryWithObject:nucleotide.font forKey:NSFontAttributeName]];
    CGFloat shim = (CGRectGetWidth(featureSurface) - letterSize.width)/2.0;

    [[UIColor whiteColor] setFill];
//    [nucleotide.text drawInRect:CGRectInset(featureSurface, shim, 0) withFont:nucleotide.font];
    [nucleotide.text drawInRect:CGRectInset(featureSurface, shim, 0) withAttributes:[NSDictionary dictionaryWithObject:nucleotide.font forKey:NSFontAttributeName]];

}

+ (void)renderZoomInAnnouncementWithRenderSurface:(CGRect)renderSurface {

    UILabel *zoomInToSeeAlignmentsLabel = (UILabel *) [UINib containerViewForNibNamed:@"ZoomInToSeeAlignments"];

    CGFloat originY = CGRectGetMinY(renderSurface) + CGRectGetMidY(zoomInToSeeAlignmentsLabel.bounds);

    [zoomInToSeeAlignmentsLabel.textColor setFill];

    CGFloat originX = CGRectGetMinX(renderSurface);
    while (originX < CGRectGetMaxX(renderSurface)) {

//        [zoomInToSeeAlignmentsLabel.text drawAtPoint:CGPointMake(originX, originY) withFont:zoomInToSeeAlignmentsLabel.font];
        [zoomInToSeeAlignmentsLabel.text drawAtPoint:CGPointMake(originX, originY) withAttributes:[NSDictionary dictionaryWithObject:zoomInToSeeAlignmentsLabel.font forKey:NSFontAttributeName]];
        originX += 1.5 * CGRectGetWidth(zoomInToSeeAlignmentsLabel.bounds);
    }

    return;
}

+ (void)renderZeroQualityAlignment:(Alignment *)alignment alignmentBounds:(CGRect)alignmentBounds {

    UIColor *strokeColor = [[AlignmentTrackView alignmentColors] objectForKey:@"grey_light"];
    [strokeColor setStroke];

    UIColor *fillColor = [UIColor clearColor];
    [fillColor setFill];

    // render alignment body
    CGRect alignmentTile = CGRectInset(alignmentBounds, 0, 1.0);

    // Fill body
    UIRectFillUsingBlendMode(alignmentTile, kCGBlendModeNormal);

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextBeginPath(context);

    if (!alignment.negativeStrand) {

        CGContextMoveToPoint(context, CGRectGetMaxX(alignmentTile), CGRectGetMinY(alignmentTile));
        CGContextAddLineToPoint(context, CGRectGetMinX(alignmentTile), CGRectGetMinY(alignmentTile));
        CGContextAddLineToPoint(context, CGRectGetMinX(alignmentTile), CGRectGetMaxY(alignmentTile));
        CGContextAddLineToPoint(context, CGRectGetMaxX(alignmentTile), CGRectGetMaxY(alignmentTile));
    } else {

        CGContextMoveToPoint(context, CGRectGetMinX(alignmentTile), CGRectGetMinY(alignmentTile));
        CGContextAddLineToPoint(context, CGRectGetMaxX(alignmentTile), CGRectGetMinY(alignmentTile));
        CGContextAddLineToPoint(context, CGRectGetMaxX(alignmentTile), CGRectGetMaxY(alignmentTile));
        CGContextAddLineToPoint(context, CGRectGetMinX(alignmentTile), CGRectGetMaxY(alignmentTile));
    }

    CGContextStrokePath(context);

    // render alignment arrow head
    [self renderArrowHeadWithAlignment:alignment fillColor:fillColor strokeColor:strokeColor alignmentBounds:alignmentTile];
}

+ (void)renderArrowHeadWithAlignment:(Alignment *)alignment fillColor:(UIColor *)fillColor strokeColor:(UIColor *)strokeColor alignmentBounds:(CGRect)alignmentBounds {

    //
    // In Photoshop parlence
    // w - width of base of arrowhead triangle
    // h - length from arrowhead triangle base to point
    // photoShopArrowhead = CGSizeMake(w, h);
    //

    float x = !alignment.negativeStrand ? CGRectGetMaxX(alignmentBounds) : CGRectGetMinX(alignmentBounds);
    float y = CGRectGetMinY(alignmentBounds);

    CGSize arrowHeadSize = CGSizeMake(CGRectGetHeight(alignmentBounds), 1 * CGRectGetHeight(alignmentBounds));
    float dx = !alignment.negativeStrand ? arrowHeadSize.height : -arrowHeadSize.height;

    CGContextRef context = UIGraphicsGetCurrentContext();

    // fill arrowhead
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, x, y);
    CGContextAddLineToPoint(context, x + dx, y + arrowHeadSize.width / 2);
    CGContextAddLineToPoint(context, x, y + arrowHeadSize.width);
    CGContextClosePath(context);

    [fillColor setFill];
    CGContextFillPath(context);

    // stroke arrowhead
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, x, y);
    CGContextAddLineToPoint(context, x + dx, y + arrowHeadSize.width / 2);
    CGContextAddLineToPoint(context, x, y + arrowHeadSize.width);

    [strokeColor setStroke];
    CGContextStrokePath(context);
}

+ (void)renderGapWithAlignmentBounds:(CGRect)alignmentBounds alignmentGapLineStyle:(char)alignmentGapLineStyle {

    UIColor *gapColor;
    CGRect gapLine;

    if ('N' == alignmentGapLineStyle) {

        // spliced alignment
        gapColor = [UIColor lightGrayColor];
        gapLine = CGRectInset(alignmentBounds, 0, CGRectGetHeight(alignmentBounds) * (0.47));
    } else {

        // deletion
        gapColor = [UIColor darkGrayColor];
        gapLine = CGRectInset(alignmentBounds, 0, (alignmentBounds.size.height - 2) / 2);
    }

    [gapColor setFill];
    UIRectFill(gapLine);

}

- (void)renderAlignmentBlock:(AlignmentBlock *)alignmentBlock backdrop:(CGRect)backdrop color:(UIColor *)color pointPerBases:(CGFloat)pointPerBases featureIntervalStart:(long long int)featureIntervalStart {

    long long exe = alignmentBlock.start - featureIntervalStart;

    CGRect tile = CGRectMake(pointPerBases * exe, CGRectGetMinY(backdrop), pointPerBases * alignmentBlock.length, CGRectGetHeight(backdrop));

    [color setFill];
    UIRectFill(tile);

}

- (void)renderArrowHeadWithAlignmentBBox:(CGRect)alignmentBBox strand:(BOOL)strand color:(UIColor *)color {

    //
    // In Photoshop parlence
    // w - width of base of arrowhead triangle
    // h - length from arrowhead triangle base to point
    // photoShopArrowhead = CGSizeMake(w, h);
    //

    float x = !strand ? CGRectGetMaxX(alignmentBBox) : CGRectGetMinX(alignmentBBox);
    float y = CGRectGetMinY(alignmentBBox);

    CGSize arrowHeadSize = CGSizeMake(CGRectGetHeight(alignmentBBox), 1 * CGRectGetHeight(alignmentBBox));
    float dx = !strand ? arrowHeadSize.height : -arrowHeadSize.height;

    [color setFill];

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextBeginPath(context);
    CGContextMoveToPoint(context, x, y);
    CGContextAddLineToPoint(context, x + dx, y + arrowHeadSize.width / 2);
    CGContextAddLineToPoint(context, x, y + arrowHeadSize.width);
    CGContextClosePath(context);

    CGContextDrawPath(context, kCGPathFill);

}

@end
