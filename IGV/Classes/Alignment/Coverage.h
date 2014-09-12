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


#import <Foundation/Foundation.h>

@class Alignment;
@class AlignmentBlock;
@class IGVContext;
@class FeatureInterval;
@class RefSeqFeatureSource;

@interface NSMutableArray (MismatchItem)
- (void)sortNucleotideLetters;
- (NSArray *)getRenderList;
@end

@interface Coverage : NSObject
- (id)initWithRefSeqFeatureSource:(RefSeqFeatureSource *)refSeqFeatureSource;
@property(nonatomic) NSUInteger *coverageList;
@property(nonatomic) unsigned long maximumCoverage;
@property(nonatomic, retain) NSMutableDictionary * mismatches;
@property(nonatomic, retain) RefSeqFeatureSource *refSeqFeatureSource;

- (void)accumulateCoverageWithAlignment:(Alignment *)alignment;

- (NSMutableArray *)mismatchListWithGenomicLocation:(long long int)genomicLocation;

- (CGFloat)mismatchQualitySummationWithMismatchList:(NSMutableArray *)mismatchList;

- (NSUInteger)coverageWithGenomicLocation:(long long int)genomicLocation;

- (CGFloat)qualityWeightedMismatchPercentageWithGenomicLocation:(long long int)genomicLocation;

+ (id)keyForMismatchesWithLocation:(long long int)location refSeqLetter:(NSString *)refSeqLetter;
+ (CGFloat)mismatchPercentageThreshold;

@end