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
//  Created by turner on 3/20/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "RefSeqRenderer.h"
#import "FeatureList.h"
#import "Logging.h"
#import "RefSeqFeatureList.h"
#import "IGVHelpful.h"
#import "TrackView.h"
#import "IGVContext.h"
#import "UIApplication+IGVApplication.h"
#import "RefSeqFeatureSource.h"
#import "RefSeqTrackView.h"
#import "FeatureInterval.h"
#import "LocusListItem.h"

CGFloat const kNucleotideLetterRenderThreshold = 18.0;

@implementation RefSeqRenderer

- (void)renderInRect:(CGRect)rect featureList:(FeatureList *)featureList trackProperties:(NSDictionary *)trackProperties track:(TrackView *)track {

    CGRect renderSurface = [TrackView renderSurfaceWithTrackRect:rect];

    if (nil == featureList) {

        [[UIColor whiteColor] set];
        UIRectFill(renderSurface);
        return;
    }

    [[UIColor clearColor] set];
    UIRectFill(renderSurface);

    IGVContext *igvContext = [IGVContext sharedIGVContext];
    double ppb = [igvContext pointsPerBase];


    LocusListItem *locusListItem = [igvContext currentLocusListItem];
    FeatureInterval *featureInterval = [igvContext currentFeatureInterval];
    RefSeqFeatureSource *refSeqFeatureSource = [UIApplication sharedRootContentController].refSeqTrack.featureSource;

    // The rect length and featureInterval are synonyms
//    NSString *rectLength = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithDouble:floor(CGRectGetWidth(rect) / ppb)]];
//    NSString *featureIntervalLength = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:[igvContext currentFeatureInterval].length]];


    // Examine deltas at endpoints
//    NSLog(@"delta %lld %lld", featureInterval.start - refSeqFeatureSource.start, refSeqFeatureSource.end - featureInterval.end);

    long long int featureIntervalIndex;
    long long int genomicLocation;
    for (featureIntervalIndex = 0, genomicLocation = featureInterval.start; genomicLocation < featureInterval.end; featureIntervalIndex++, genomicLocation++) {

        NSString *nucleotideLetter = [refSeqFeatureSource refSeqLetterWithGenomicLocation:genomicLocation];

        if (nil == nucleotideLetter) {
            continue;
        }

        UILabel *nucleotideLetterLabel = [igvContext.nucleotideLetterLabels objectForKey:nucleotideLetter];

        if (nil == nucleotideLetterLabel) {
            continue;
        }

        CGRect tile = CGRectMake((CGFloat)(ppb * featureIntervalIndex), CGRectGetMinY(renderSurface), (CGFloat)ppb, CGRectGetHeight(renderSurface));

        [nucleotideLetterLabel.textColor setFill];
        UIRectFill(tile);

        // if tile is large enough draw letter
        if (ppb > kNucleotideLetterRenderThreshold) {

            CGSize letterSize = [nucleotideLetterLabel.text sizeWithAttributes:[NSDictionary dictionaryWithObject:nucleotideLetterLabel.font forKey:NSFontAttributeName]];
            CGFloat shim = (CGRectGetWidth(tile) - letterSize.width)/2.0;

            NSArray *keys = [NSArray arrayWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, nil];
            NSArray *objs = [NSArray arrayWithObjects:nucleotideLetterLabel.font, [UIColor whiteColor], nil];
            NSDictionary *attributes = [NSDictionary dictionaryWithObjects:objs forKeys:keys];

            [nucleotideLetterLabel.text drawInRect:CGRectInset(tile, shim, -1) withAttributes:attributes];
        }

    }

}

@end