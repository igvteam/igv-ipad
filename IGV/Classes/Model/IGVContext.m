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
//  IGVContext.m
//  InfiniteScroll
//
//  Created by Douglass Turner on 12/25/11.
//  Copyright (c) 2011 Home. All rights reserved.
//

#import "FeatureInterval.h"
#import "IGVContext.h"
#import "RootScrollView.h"
#import "Cytoband.h"
#import "GenomeManager.h"
#import "Logging.h"
#import "NSArray+Cytoband.h"
#import "LocusListItem.h"
#import "IGVHelpful.h"
#import "UIApplication+IGVApplication.h"

@implementation
IGVContext

@synthesize nucleotideLetterLabels;
@synthesize start = _start;
@synthesize end = _end;
@synthesize chromosomeName = _chromosomeName;

- (void)dealloc {

    self.nucleotideLetterLabels = nil;
    self.chromosomeName = nil;

    [super dealloc];
}

- (NSMutableDictionary *)nucleotideLetterLabels {

    if (nil == nucleotideLetterLabels) {

        self.nucleotideLetterLabels = [NSMutableDictionary dictionary];

        // Use the nib file for creating subview tiles.
        UIView *nucleotideLettersSketchbook = [[[UINib nibWithNibName:@"NucleotideLetters" bundle:nil] instantiateWithOwner:nil options:nil] objectAtIndex:0];

        // A, C, G, and T, representing the four nucleotide bases of a DNA strand:
        // Adenine, Cytosine, Guanine, Thymine
        //
        // See: http://en.wikipedia.org/wiki/Genetic_sequence
        //        A adenine
        //        C cytosine
        //        G guanine
        //        T thymine
        //
        for (UILabel *nucleotideLetterLabel in nucleotideLettersSketchbook.subviews) {
            [self.nucleotideLetterLabels setObject:nucleotideLetterLabel forKey:nucleotideLetterLabel.text];
        }
    }

    return nucleotideLetterLabels;
}

- (double)pointsPerBase {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];

    double points = [rootContentController.rootScrollView contentWidth];
    double bases = [self length];

    double ppb = rootContentController.rootScrollView.zoomScale * (points/bases);

    return ppb;
}

- (NSInteger)zoomLevel {

    NSArray *chromosomeExtent = [[GenomeManager sharedGenomeManager] currentChromosomeExtent];
    if(nil == chromosomeExtent) return 0;

    double chrLength = [chromosomeExtent length];
    double scale = chrLength / (double)[[self currentLocusListItem] length];
    NSInteger zoomLevel =  (NSInteger)MAX(0, floor(log2(scale)));
    return zoomLevel;
}

- (CGFloat)chromosomeZoomWithLocusListItem:(LocusListItem *)locusListItem {

    CGFloat numer = [locusListItem length];

    NSArray *chr = [[GenomeManager sharedGenomeManager] chromosomeExtentWithChromosomeName:self.chromosomeName];
    CGFloat denom = [chr length];

    return numer/denom;
}

- (long long int)length {

    return self.end - self.start;
}

- (FeatureInterval *)currentFeatureInterval {

    NSArray *chromosomeExtent = [[GenomeManager sharedGenomeManager] currentChromosomeExtent];
    if (nil == chromosomeExtent) {
        return nil;
    } else {
        return [FeatureInterval intervalWithChromosomeName:self.chromosomeName start:MAX([chromosomeExtent start], self.start) end:MIN([chromosomeExtent end], self.end) zoomLevel:[self zoomLevel]];
    }

}

- (NSString *)currentLocus {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];

    double left;
    double right;
    [rootContentController.rootScrollView locusWithIGVContextStart:self.start locusStart:&left locusEnd:&right];

    if (0 == nearbyint(left) && 0 == nearbyint(right)) {
        return nil;
    }

    return [NSString stringWithFormat:@"%@:%.0f-%.0f", self.chromosomeName, nearbyint(left), nearbyint(right)];
}

- (LocusListItem *)currentLocusListItem {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];

    double locusStart;
    double locusEnd;
    [rootContentController.rootScrollView locusWithIGVContextStart:[IGVContext sharedIGVContext].start locusStart:&locusStart locusEnd:&locusEnd];

    NSString *locus = [NSString stringWithFormat:@"%@:%.0f-%.0f", self.chromosomeName, nearbyint(locusStart), nearbyint(locusEnd)];

    LocusListFormat locusListFormat = [locus format];
    if ([rootContentController.rootScrollView willDisplayEntireChromosomeName:[IGVContext sharedIGVContext].chromosomeName start:locusStart end:locusEnd]) {

        locus = [IGVContext sharedIGVContext].chromosomeName;
        locusListFormat = LocusListFormatChrFullExtent;
    }

    LocusListItem *locusListItem = [[[LocusListItem alloc] initWithLocus:locus
                                                                   label:nil locusListFormat:locusListFormat
                                                              genomeName:[GenomeManager sharedGenomeManager].currentGenomeName] autorelease];

    return locusListItem;
}

+(IGVContext *)sharedIGVContext {

    static dispatch_once_t pred;
    static IGVContext *shared = nil;

    dispatch_once(&pred, ^{

        shared = [[IGVContext alloc] init];
    });

    return shared;

}

- (void)setWithLocusStart:(long long int)locusStart locusEnd:(long long int)locusEnd locusOffsetComparisonBases:(double *)locusOffsetComparisonBases {

    long long locusLength = llround(locusEnd - locusStart + 1);

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    *locusOffsetComparisonBases = [rootContentController.rootScrollView locusOffsetUsingRootScrollviewUnitOfMeasturePoints] / (((double)CGRectGetWidth(rootContentController.rootScrollView.bounds))/((double) locusLength));

    NSArray *chromosomeExtent = [[GenomeManager sharedGenomeManager] chromosomeExtentWithChromosomeName:self.chromosomeName];
    if (*locusOffsetComparisonBases > locusStart) {

        self.start = [chromosomeExtent start];
        self.end   = llround(2.0 * (*locusOffsetComparisonBases)) + locusLength - 1;
    } else if (*locusOffsetComparisonBases > ([chromosomeExtent end] - locusEnd)) {

        self.end   = [chromosomeExtent end];
        self.start = self.end + 1 - (locusLength + llround(2.0 * (*locusOffsetComparisonBases)));
    } else {

        self.start = llround(locusStart - *locusOffsetComparisonBases);
        self.end   = llround(locusEnd + *locusOffsetComparisonBases);
    }

}

- (NSString *)description {

//    NSArray *chromosomeExtent = [[GenomeManager sharedGenomeManager] chromosomeExtentWithChromosomeName:self.chromosomeName];
//    NSString *chrLength = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:[chromosomeExtent length]]];
//
//    return [NSString stringWithFormat:@"%@ zoomLevel %d %@ chr length %@", [self class], [self zoomLevel], [self currentLocusListItem], chrLength];

    NSString *ll = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:[self length]]];
    NSString *ss = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:self.start]];
    return [NSString stringWithFormat:@"%@ start %@ length %@", [self class], ss, ll];
}

@end
