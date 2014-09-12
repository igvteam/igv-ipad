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
//  AlignmentRow.m
//  
//  Represents a row of packed alignments.
//
//  Created by turner on 10/15/09.
//  Copyright 2009 Douglass Turner Consulting. All rights reserved.
//

#import "AlignmentRow.h"
#import "IGVHelpful.h"
#import "Logging.h"
#import "AlignmentBlock.h"
#import "AlignmentBlockItem.h"
#import "UIApplication+IGVApplication.h"
#import "RootContentController.h"
#import "RefSeqTrackView.h"
#import "RefSeqFeatureList.h"
#import "IGVContext.h"
#import "FeatureInterval.h"
#import "Coverage.h"
#import "RefSeqFeatureSource.h"

NSComparator const kAlignmentRowSortComparatorNull = ^(AlignmentRow *a, AlignmentRow *b) {
    return NSOrderedSame;
};

NSComparator const kAlignmentRowSortComparatorSortOnStart = ^(AlignmentRow *a, AlignmentRow *b) {

    if (a.start == b.start) return NSOrderedSame;
    return (a.start < b.start) ? NSOrderedAscending : NSOrderedDescending;
};

@implementation NSMutableArray (AlignmentRowSort)

- (NSMutableArray *)sortWithBaseAtLocation:(NSNumber *)location coverage:(Coverage *)coverage {

    RefSeqFeatureSource *refSeqFeatureSource = [UIApplication sharedRootContentController].refSeqTrack.featureSource;
    long long sortLocation = [location longLongValue];

    // ref seq base
    NSString *refSeqLetter = [refSeqFeatureSource refSeqLetterWithGenomicLocation:sortLocation];

    NSString *key = [Coverage keyForMismatchesWithLocation:sortLocation refSeqLetter:refSeqLetter];

    // At location: if no mismatches or if the quality weighted mismatch percentage falls below the threshold, then search within a neighborhood for an acceptable mismatch.
    // If an acceptable mismatch is found - one that results in rendering a colored mismatch bar - then use that location to perform the search.
    if ( ![coverage.mismatches objectForKey:key] || [coverage qualityWeightedMismatchPercentageWithGenomicLocation:sortLocation] < [Coverage mismatchPercentageThreshold] ) {

        NSUInteger halfWidth = (NSUInteger)((1.0/[[IGVContext sharedIGVContext] pointsPerBase]) * [Alignment mismatchSearchWindow]);
        halfWidth >>= 1;

        NSMutableArray *coverageMismatchHits = [NSMutableArray array];
        for (long long int genomicLocation = sortLocation - halfWidth; genomicLocation <= sortLocation + halfWidth; genomicLocation++) {

            NSString *letter = [refSeqFeatureSource refSeqLetterWithGenomicLocation:genomicLocation];
            if (nil == letter) {

                [coverageMismatchHits addObject:[NSNull null]];
                continue;
            }

            key = [Coverage keyForMismatchesWithLocation:genomicLocation refSeqLetter:letter];
            if ([coverage.mismatches objectForKey:key] && [coverage qualityWeightedMismatchPercentageWithGenomicLocation:genomicLocation] >= [Coverage mismatchPercentageThreshold]) {

                [coverageMismatchHits addObject:[NSNumber numberWithLongLong:genomicLocation]];
            } else {

                [coverageMismatchHits addObject:[NSNull null]];
            }

        } // for (loc)

        long long int minimum = (long long int)[Alignment mismatchSearchWindow];
        for (id item in coverageMismatchHits) {

            if (item != [NSNull null]) {
                if (llabs([item longLongValue] - sortLocation) < minimum) {

                    minimum = llabs([item longLongValue] - sortLocation);
                    sortLocation = [item longLongValue];

                    refSeqLetter = [refSeqFeatureSource refSeqLetterWithGenomicLocation:sortLocation];
                }
            }
        }
    }

    NSMutableSet *mismatchSet = [NSMutableSet set];
    NSMutableSet *matchSet = [NSMutableSet set];
    for (AlignmentRow *alignmentRow in self) {

        // initialize to nil
        alignmentRow.alignmentBlockItem = nil;

        // record found alignmentBlockItem if any
        alignmentRow.alignmentBlockItem = [alignmentRow alignmentBlockItemAtLocation:sortLocation];

        if (nil == alignmentRow.alignmentBlockItem) {
            continue;
        }

        // accumulate matchSet and mismatchSet
        if ([refSeqLetter isEqualToString:alignmentRow.alignmentBlockItem.base]) {
            [matchSet addObject:alignmentRow];
        } else {
            [mismatchSet addObject:alignmentRow];
        }
    }

    // do nothing if there are no mismatchSet
    if (0 == [mismatchSet count]) {
        return self;
    }

    NSMutableSet *misSet = [NSMutableSet setWithArray:self];
    [misSet minusSet:matchSet];
    [misSet minusSet:mismatchSet];

    NSSortDescriptor *baseSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"alignmentBlockItem.base"
                                                                         ascending:NO
                                                                          selector:@selector(localizedStandardCompare:)];

    NSSortDescriptor *qualitySortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"alignmentBlockItem.quality"
                                                                            ascending:NO
                                                                           comparator:(NSComparator) ^(NSNumber *a, NSNumber *b) {

                                                                               CGFloat aAlpha = [Alignment alphaFromQuality:[a unsignedCharValue]];
                                                                               CGFloat bAlpha = [Alignment alphaFromQuality:[b unsignedCharValue]];

                                                                               return [[NSNumber numberWithFloat:aAlpha] compare:[NSNumber numberWithFloat:bAlpha]];
                                                                           }];

    // 1) append mismatchSet
    NSMutableArray *mismatchList = [NSMutableArray arrayWithArray:[mismatchSet allObjects]];
    NSMutableArray *accumulation = [NSMutableArray arrayWithArray:[mismatchList sortedArrayUsingDescriptors:[NSArray arrayWithObjects:baseSortDescriptor, qualitySortDescriptor, nil]]];

    // 2) append matchSet
    if ([matchSet count] > 0) [accumulation addObjectsFromArray:[matchSet allObjects]];

    // 3) append everything else (misSet)
    if ([misSet count] > 0) [accumulation addObjectsFromArray:[misSet allObjects]];

    return accumulation;
}

@end

@implementation AlignmentRow

@synthesize start = _start;
@synthesize end = _end;
@synthesize alignments = _alignments;
@synthesize alignmentBlockItem = _alignmentBlockItem;
@synthesize alignmentRowSortComparator = _alignmentRowSortComparator;

- (void) dealloc {

    self.alignments = nil;
    self.alignmentBlockItem = nil;
    self.alignmentRowSortComparator = nil;

    [super dealloc];
}

-(id)init {
    
    self = [super init];
    if (nil != self) {
        self.start = NSIntegerMax;
        self.end   = NSIntegerMin;
    }    
    return self;
}

- (NSMutableArray *)alignments{

    if (nil == _alignments) {
        self.alignments = [NSMutableArray array];
    }

    return _alignments;
}

- (NSComparator)alignmentRowSortComparator {

    if (nil == _alignmentRowSortComparator) {
        self.alignmentRowSortComparator = kAlignmentRowSortComparatorNull;
    }

    return _alignmentRowSortComparator;
}

#pragma mark -
#pragma mark AlignmentRow methods

- (void)addAlignment:(Alignment *)alignment {

    [self.alignments insertObject:alignment atIndex:0];

    self.start = MIN(self.start, alignment.start);
    self.end   = MAX(self.end,   alignment.end);
}

- (void)sortViaAlignmentStart {

    [self.alignments sortUsingComparator:(NSComparator)^(Alignment *a, Alignment *b) {
        if (a.start == b.start) return NSOrderedSame;
        return (a.start < b.start) ? NSOrderedAscending : NSOrderedDescending;
    }];

}

-(AlignmentBlockItem *)alignmentBlockItemAtLocation:(long long int)location {

    AlignmentBlockItem *alignmentBlockItem = nil;

    for (Alignment *alignment in self.alignments) {

        alignmentBlockItem = [alignment alignmentBlockItemAtLocation:location];

        if (nil != alignmentBlockItem) {
            return alignmentBlockItem;
        }
    }

    return alignmentBlockItem;
}

-(BOOL)alignmentHitTest:(long long int)value {

    __block BOOL success = NO;

    [self.alignments enumerateObjectsUsingBlock:^(Alignment *alignment, NSUInteger index, BOOL *stop){

        if ([alignment bboxHitTest:value]) {
            success = YES;
            *stop = YES;
        }
    } ];

    return success;
}

- (long long int)minimumAlignmentStart {

    __block  long long int start = NSIntegerMax;
    [self.alignments enumerateObjectsUsingBlock:^(Alignment *alignment, NSUInteger index, BOOL *ignore){
        start = MIN(start, alignment.start);
    } ];

    return start;
}

- (long long int)maximumAlignmentEnd {

    __block  long long int end = NSIntegerMin;
    [self.alignments enumerateObjectsUsingBlock:^(Alignment *alignment, NSUInteger index, BOOL *ignore){
        end = MAX(end, alignment.end);
    } ];

    return end;

}

- (NSString *)description {

    NSString *accumulation = @"";
    for (Alignment *alignment in self.alignments) {

        NSString *sss = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:alignment.start]];
        NSString *eee = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:  alignment.end]];
        accumulation = [accumulation stringByAppendingString:[NSString stringWithFormat:@"%@ %@ ", sss, eee]];
    }

    NSString *ss = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:self.start]];
    NSString *ee = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:  self.end]];

    return [NSString stringWithFormat:@"%@ start %@ end %@. %@", [self class], ss, ee, accumulation];
}

@end
