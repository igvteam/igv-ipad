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
//  Created by turner on 4/5/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "CoverageRenderer.h"
#import "CoverageTrackView.h"
#import "AlignmentTrackView.h"
#import "Logging.h"
#import "AlignmentResults.h"
#import "Coverage.h"
#import "FeatureList.h"
#import "RefSeqTrackView.h"
#import "RefSeqFeatureList.h"
#import "RefSeqTrackController.h"
#import "RefSeqFeatureSource.h"
#import "IGVHelpful.h"
#import "UIApplication+IGVApplication.h"
#import "IGVContext.h"
#import "FeatureInterval.h"

@interface CoverageRenderer ()
@end

@implementation CoverageRenderer

- (void)renderInRect:(CGRect)rect track:(CoverageTrackView *)coverageTrack {

    [[UIColor clearColor] setFill];
    UIRectFill(rect);

    if ([AlignmentTrackView isBelowFeatureRenderingThreshold]) {
        return;
    }

    if (nil == coverageTrack.alignmentResults) {
        return;
    }

    IGVContext *igvContext = [IGVContext sharedIGVContext];
    CGFloat ppb = (CGFloat) [igvContext pointsPerBase];

    Coverage *coverage = coverageTrack.alignmentResults.coverage;

    // clear background to white
    [[UIColor whiteColor] setFill];
    UIRectFill(rect);

    UIColor *defaultColor = [[AlignmentTrackView alignmentColors] objectForKey:@"grey_medium"];

    CGFloat rectWidth = ceilf(ppb);
    CGFloat rectHeight = CGRectGetHeight(rect);

    FeatureInterval *featureInterval = [[IGVContext sharedIGVContext] currentFeatureInterval];

    long long int genomicLocation;
    CGFloat x;

    for (genomicLocation = featureInterval.start, x = CGRectGetMinX(rect); genomicLocation < featureInterval.end; genomicLocation++, x += ppb) {

        if ([coverage coverageWithGenomicLocation:genomicLocation] <= 0) {
            continue;
        }

        // 0 to 1
        CGFloat coveragePercentage = ((CGFloat)[coverage coverageWithGenomicLocation:genomicLocation]) / ((CGFloat)coverage.maximumCoverage);

        CGRect coverageRenderTile = CGRectMake(x, (1.0 - coveragePercentage) * rectHeight, rectWidth, coveragePercentage * rectHeight);

        [defaultColor setFill];
        UIRectFill(coverageRenderTile);

        CGFloat mismatchPercentage = [coverage qualityWeightedMismatchPercentageWithGenomicLocation:genomicLocation];
        if (mismatchPercentage > [Coverage mismatchPercentageThreshold]) {

            NSString *nucleotideLetter = [coverage.refSeqFeatureSource refSeqLetterWithGenomicLocation:genomicLocation];
            UIColor *nucleotideLetterColor = ((UILabel *) [igvContext.nucleotideLetterLabels objectForKey:nucleotideLetter]).textColor;

            [nucleotideLetterColor setFill];
            UIRectFill(coverageRenderTile);

            NSMutableArray *mismatchList = [coverage mismatchListWithGenomicLocation:genomicLocation];
            if (nil != mismatchList) {

                [mismatchList sortNucleotideLetters];

                NSArray *mismatchRenderList = [mismatchList getRenderList];

                // NOTE: This render list is in sorted order - A C G T
                CGFloat accumulatedOrigin = rectHeight;
                for (NSDictionary *dictionary in mismatchRenderList) {

                    nucleotideLetter = [[dictionary allKeys] objectAtIndex:0];

                    CGFloat heightPercentage = [[dictionary objectForKey:nucleotideLetter] floatValue];
                    heightPercentage /= ((CGFloat)[coverage coverageWithGenomicLocation:genomicLocation]);

                    CGFloat mismatchRenderTileHeight = heightPercentage * CGRectGetHeight(coverageRenderTile);
                    accumulatedOrigin -= mismatchRenderTileHeight;

                    CGRect mismatchRenderTile = CGRectMake(x, accumulatedOrigin, rectWidth, mismatchRenderTileHeight);

                    nucleotideLetterColor = ((UILabel *) [igvContext.nucleotideLetterLabels objectForKey:nucleotideLetter]).textColor;
                    [nucleotideLetterColor setFill];

                    UIRectFill(mismatchRenderTile);

                }

            }

        }

    }

    [[UIColor lightGrayColor] setFill];
    CGRect baseLine = CGRectMake(CGRectGetMinX(rect), CGRectGetMaxY(rect) - 1, CGRectGetWidth(rect), 1);
    UIRectFill(baseLine);


}

@end

