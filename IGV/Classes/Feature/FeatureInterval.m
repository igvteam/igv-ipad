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
// Created by jrobinso on 7/29/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "FeatureInterval.h"
#import "IGVHelpful.h"
#import "GenomeManager.h"
#import "NSArray+Cytoband.h"

@implementation FeatureInterval

@synthesize chromosomeName = _chromosomeName;
@synthesize start = _start;
@synthesize end = _end;
@synthesize zoomLevel = _zoomLevel;

- (void)dealloc {

    self.chromosomeName = nil;

    [super dealloc];
}

- (id)initWithChromosomeName:(NSString *)chromosomeName start:(long long int)start end:(long long int)end zoomLevel:(NSInteger)zoomLevel {

    self = [super init];

    if (nil != self) {
        self.chromosomeName = chromosomeName;
        self.start = start;
        self.end = end;
        self.zoomLevel = zoomLevel;
    }
    return self;
}

- (long long int)length {
    return self.end - self.start;
}

- (BOOL)containsFeatureInterval:(FeatureInterval *)featureInterval {

    return [self containsChromosomeName:featureInterval.chromosomeName start:featureInterval.start end:featureInterval.end zoomLevel:featureInterval.zoomLevel];
}

// Note:  Zoom level of -1 == wildcard, matches all zooms
- (BOOL)containsChromosomeName:(NSString *)chromosomeName start:(long long int)start end:(long long int)end zoomLevel:(NSInteger)zoomLevel {

    BOOL isSameChromosome = [self.chromosomeName isEqualToString:chromosomeName];
    BOOL success = isSameChromosome && self.start <= start && self.end >= end;
    // Optionally include zoom level in check.
    if (self.zoomLevel >= 0 && zoomLevel >= 0) {
        success = success && (self.zoomLevel == zoomLevel);
    }

    return success;
}

+ (id)intervalWithChromosomeName:(NSString *)chromosomeName {

    NSArray *chromosomeExtent = [[GenomeManager sharedGenomeManager] chromosomeExtentWithChromosomeName:chromosomeName];
    return [[[self alloc] initWithChromosomeName:chromosomeName start:[chromosomeExtent start] end:[chromosomeExtent end] zoomLevel:-1] autorelease];
}

+ (id)intervalWithChromosomeName:(NSString *)chromosomeName start:(long long int)start end:(long long int)end {

    return [[[self alloc] initWithChromosomeName:chromosomeName start:start end:end zoomLevel:-1] autorelease];
}

+ (id)intervalWithChromosomeName:(NSString *)chromosomeName start:(long long int)start end:(long long int)end zoomLevel:(NSInteger)zoomLevel {

    return [[[self alloc] initWithChromosomeName:chromosomeName start:start end:end zoomLevel:zoomLevel] autorelease];
}

- (NSString *)description {

    NSString *ss = (self.start == LLONG_MIN) ? @"LLONG_MIN" : [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:self.start]];
    NSString *ee = (self.start == LLONG_MIN) ? @"LLONG_MIN" : [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:self.end]];
    NSString *ll = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:[self length]]];

//    return [NSString stringWithFormat:@"%@ start %@ end %@ length %@ chr %@ zoomLevel %d", [self class], ss, ee, ll, self.chromosomeName, self.zoomLevel];


    return [NSString stringWithFormat:@"%@ start %@ length %@", [self class], ss, ll];

}

@end