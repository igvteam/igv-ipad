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
// Created by turner on 10/21/13.
//

#import "Coverage.h"
#import "IGVMath.h"
#import "AlignmentBlock.h"
#import "RootContentController.h"
#import "IGVHelpful.h"
#import "RefSeqTrackController.h"
#import "RefSeqTrackView.h"
#import "RefSeqFeatureList.h"
#import "Logging.h"
#import "CoverageMismatch.h"
#import "UIApplication+IGVApplication.h"
#import "FeatureInterval.h"
#import "RefSeqFeatureSource.h"
#import "IGVContext.h"

@implementation NSMutableArray (MismatchItem)

-(void)sortNucleotideLetters {

    [self sortUsingComparator:(NSComparator)^(CoverageMismatch *a, CoverageMismatch *b) {
        return [a.nucleotideLetter compare:b.nucleotideLetter];
    }];

}

- (NSArray *)getRenderList {

    // ASSUMPTION: The supplied array is ALREADY sorted



    NSMutableArray *renderList = [NSMutableArray array];

    NSString *currentNucleotideLetter = @"";

    for (CoverageMismatch *coverageMismatch in self) {

        if ([coverageMismatch.nucleotideLetter isEqualToString:currentNucleotideLetter]) {

            NSMutableDictionary *item = [renderList lastObject];
            NSNumber *old = [item objectForKey:currentNucleotideLetter];
            NSNumber *new = [NSNumber numberWithInteger:(1 + [old integerValue])];
            [item setObject:new forKey:currentNucleotideLetter];
        } else {

            currentNucleotideLetter = coverageMismatch.nucleotideLetter;
            NSMutableDictionary *item = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInteger:1] forKey:currentNucleotideLetter];
            [renderList addObject:item];
        }

    }

    return renderList;
}

@end

@interface Coverage ()
@property(nonatomic) CGFloat    *coverageQualityList;

- (long long int)coverageListLength;
@end

@implementation Coverage

@synthesize coverageList = _coverageList;
@synthesize coverageQualityList = _coverageQualityList;
@synthesize maximumCoverage = _maximumCoverage;
@synthesize mismatches = _mismatches;

- (void)dealloc {

    if (NULL != _coverageList) {
        free(_coverageList);
    }

    if (NULL != _coverageQualityList) {
        free(_coverageQualityList);
    }

    self.mismatches = nil;
    self.refSeqFeatureSource = nil;

    [super dealloc];
}

- (id)initWithRefSeqFeatureSource:(RefSeqFeatureSource *)refSeqFeatureSource {

    self = [super init];
    if (nil != self) {

        self.refSeqFeatureSource = refSeqFeatureSource;
        
        // Indicates "unknown"
        _maximumCoverage = NSUIntegerMax;
    }

    return self;
}

- (id)init {

    self = [super init];
    if (nil != self) {

        // Indicates "unknown"
        _maximumCoverage = NSUIntegerMax;
    }

    return self;
}

- (NSUInteger *)coverageList {

    if (NULL == _coverageList) {

        _coverageList = (NSUInteger *) malloc((size_t) (sizeof(NSUInteger) * [self coverageListLength]));
        for (int i = 0; i < [self coverageListLength]; i++) {
            _coverageList[i] = 0;
        }
    }

    return _coverageList;
}

- (CGFloat *)coverageQualityList {

    if (NULL == _coverageQualityList) {

        _coverageQualityList = (CGFloat *) malloc((size_t) (sizeof(CGFloat) * [self coverageListLength]));
        for (int i = 0; i < [self coverageListLength]; i++) {
            _coverageQualityList[i] = 0.0;
        }
    }

    return _coverageQualityList;
}

- (NSMutableDictionary *)mismatches {

    if (nil == _mismatches) {

        self.mismatches = [NSMutableDictionary dictionary];
    }

    return _mismatches;
}

- (unsigned long) maximumCoverage {

    if (_maximumCoverage == NSUIntegerMax) {

        if (nil != self.coverageList) {

            // Use the 95th percentile
            _maximumCoverage = [IGVMath percentileForArray:self.coverageList size:(int)[self coverageListLength] percentile:95];
        }
    }

    return _maximumCoverage;
}

-(long long int)coverageListLength {

    return (self.refSeqFeatureSource.end - self.refSeqFeatureSource.start);
}

- (void)accumulateCoverageWithAlignment:(Alignment *)alignment {

    for (AlignmentBlock *alignmentBlock in alignment.alignmentBlocks) {

        NSInteger alignmentBlockIndex;
        long long int genomicLocation;

        for (alignmentBlockIndex = 0, genomicLocation = alignmentBlock.start; alignmentBlockIndex < alignmentBlock.length; alignmentBlockIndex++, genomicLocation++) {

            // alignment block letter
            NSString *alignmentBlockLetter = [NSString stringWithFormat:@"%c", [alignmentBlock bases][alignmentBlockIndex]];

            // ref seq letter
            NSString *refSeqLetter = [self.refSeqFeatureSource refSeqLetterWithGenomicLocation:genomicLocation];
            if (nil == refSeqLetter) {
                continue;
            }

            // check for mismatch
            if (![refSeqLetter isEqualToString:alignmentBlockLetter]) {

                // create dictionary key from genomic location and ref seq letter
                NSString *key = [Coverage keyForMismatchesWithLocation:genomicLocation refSeqLetter:refSeqLetter];

                NSMutableArray *mismatchList = [self.mismatches objectForKey:key];
                if (nil == mismatchList) {
                    mismatchList = [NSMutableArray array];
                }

                [mismatchList addObject:[[[CoverageMismatch alloc] initWithAlignmentBlock:alignmentBlock alignmentBlockIndex:alignmentBlockIndex] autorelease]];

                [self.mismatches setObject:mismatchList forKey:key];
            }

            long long int index = genomicLocation - self.refSeqFeatureSource.start;
            self.coverageList[index]++;
            self.coverageQualityList[index] += [Alignment alphaFromQuality:[alignmentBlock qualities][alignmentBlockIndex]];

        }
    }

}

- (NSUInteger)coverageWithGenomicLocation:(long long int)genomicLocation {

    long long index = genomicLocation - self.refSeqFeatureSource.start;

    if (index < 0 || index >= [self coverageListLength]) {
        return 0;
    }

    return self.coverageList[index];
}


- (CGFloat)qualityWeightedMismatchPercentageWithGenomicLocation:(long long int)genomicLocation {

    NSMutableArray *mismatchList = [self mismatchListWithGenomicLocation:genomicLocation];

    if (nil == mismatchList || [mismatchList count] == 0) {
        return 0;
    }

    CGFloat mismatchQualitySummation = [self mismatchQualitySummationWithMismatchList:mismatchList];
    CGFloat matchQualitySummation = self.coverageQualityList[(genomicLocation - self.refSeqFeatureSource.start)];

    return mismatchQualitySummation / matchQualitySummation;
}

- (NSMutableArray *)mismatchListWithGenomicLocation:(long long int)genomicLocation {

    NSString *refSeqLetter = [self.refSeqFeatureSource refSeqLetterWithGenomicLocation:genomicLocation];

    if (nil == refSeqLetter) {
        return nil;
    }

    NSString *key = [Coverage keyForMismatchesWithLocation:genomicLocation refSeqLetter:refSeqLetter];

    if (nil == key ) {
        return nil;
    }

    return [self.mismatches objectForKey:key];
}

- (CGFloat)mismatchQualitySummationWithMismatchList:(NSMutableArray *)mismatchList {

    CGFloat qualitySummation = 0;
    for (CoverageMismatch *coverageMismatch in mismatchList) {
        qualitySummation += coverageMismatch.quality;
    }

    return qualitySummation;
}

+ (id)keyForMismatchesWithLocation:(long long int)location refSeqLetter:(NSString *)refSeqLetter {

    return [NSString stringWithFormat:@"%@#%lld", refSeqLetter, location];
}

+ (CGFloat)mismatchPercentageThreshold {
    return 0.20;
}

- (NSString *)description {

    NSString *length = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:[self coverageListLength]]];
    return [NSString stringWithFormat:@"%@. coverage list length %@.", [self class], length];
}

@end