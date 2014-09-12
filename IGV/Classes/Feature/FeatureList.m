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
//  Created by turner on 3/30/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "FeatureList.h"
#import "LabeledFeature.h"
#import "FeatureInterval.h"

@interface FeatureList ()
- (id)initWithChromosome:(NSString *)chromosome start:(long long int)start end:(long long int)end zoom:(NSInteger)zoom features:(NSArray *)features;
- (id)initWithFeatureInterval:(FeatureInterval *)featureInterval alignments:(NSMutableArray *)alignments;
- (id)initWithChromosome:(NSString *)chromosome start:(long long int)start end:(long long int)end zoom:(int)zoom alignments:(NSMutableArray *)alignments;
@end

@implementation FeatureList

@synthesize features = _features;
@synthesize featureInterval = _featureInterval;

- (void)dealloc {

    self.featureInterval = nil;
    self.features = nil;

    [super dealloc];
}

- (id)initEmptyFeatureListForInterval:(FeatureInterval *)featureInterval {

    self = [super init];

    if (nil != self) {

        self.featureInterval = featureInterval;
        self.features = [NSMutableArray array];
    }

    return self;
}

- (id)initEmptyForChr:(NSString *)aChr {

    self = [super init];

    if (nil != self) {

        self.featureInterval = [FeatureInterval intervalWithChromosomeName:aChr];

        // zero length array
        self.features = [NSMutableArray array];
    }

    return self;
}

- (id)initWithChromosome:(NSString *)chromosome start:(long long int)start end:(long long int)end zoom:(NSInteger)zoom features:(NSArray *)features {

    self = [super init];
    
    if (nil != self) {
        
        self.featureInterval = [FeatureInterval intervalWithChromosomeName:chromosome start:start end:end zoomLevel:zoom];

        NSArray *sortedFeatures;
        sortedFeatures = [features sortedArrayUsingComparator:^NSComparisonResult(Feature *a, Feature *b) {
            if (a.start == b.start) return NSOrderedSame;
            return (a.start < b.start) ? NSOrderedAscending : NSOrderedDescending;
        }];

        self.features = [NSMutableArray arrayWithArray:sortedFeatures];
        
        float minScore = CGFLOAT_MAX;
        float maxScore = -CGFLOAT_MAX;
        for(Feature *f in self.features) {
            minScore = MIN(minScore, f.score);
            maxScore = MAX(maxScore, f.score);
        }
        self.minScore = minScore;
        self.maxScore = maxScore;

    }
    
    return self;
}

- (id)initWithFeatureInterval:(FeatureInterval *)featureInterval alignments:(NSMutableArray *)alignments {

    self = [super init];

    if (nil != self) {

        self.featureInterval = featureInterval;
        self.features = alignments;
    }

    return self;

}

- (id)initWithChromosome:(NSString *)chromosome start:(long long int)start end:(long long int)end zoom:(int)zoom alignments:(NSMutableArray *)alignments {

    self = [super init];

    if (nil != self) {

        self.featureInterval = [FeatureInterval intervalWithChromosomeName:chromosome start:start end:end zoomLevel:zoom];
        self.features = alignments;
    }

    return self;
}

- (long long)minimumFeatureStart {

    long long minimum = NSIntegerMax;

    for (LabeledFeature *feature in self.features) {
        minimum = MIN(minimum, feature.start);
    }

    return minimum;
}

- (long long)maximumFeatureEnd {

    long long maximum = NSIntegerMin;

    for (LabeledFeature *feature in self.features) {
        maximum = MAX(maximum, feature.end);
    }

    return maximum;
}

+ (id)featureListWithFeatureInterval:(FeatureInterval *)featureInterval alignments:(NSMutableArray *)alignments {
    return [[[self alloc] initWithFeatureInterval:featureInterval alignments:alignments] autorelease];
}

+ (id)featureListForFeatureInterval:(FeatureInterval *)featureInterval features:(NSArray *)features {
    return [[[self alloc] initWithChromosome:featureInterval.chromosomeName start:featureInterval.start end:featureInterval.end zoom:featureInterval.zoomLevel features:features] autorelease];
}

+ (id)featureListForChromosome:(NSString *)chromosome features:(NSArray *)features {
    return [[[self alloc] initWithChromosome:chromosome start:0 end:NSIntegerMax zoom:-1 features:features] autorelease];
}

+ (id)featureListForChromosome:(NSString *)chromosome start:(long long int)start end:(long long int)end features:(NSArray *)features {
    return [[[self alloc] initWithChromosome:chromosome start:start end:end zoom:-1 features:features] autorelease];
}

+ (id)emptyFeatureListForInterval:(FeatureInterval *)featureInterval {
    return [[[self alloc] initEmptyFeatureListForInterval:featureInterval] autorelease];
}

+ (id)emptyFeatureListForChromosome:(NSString *)chromosome {
    return [[[self alloc] initEmptyForChr:chromosome] autorelease];
}

- (NSString *)stringFromFeatureClass {
    return (0 == [self.features count]) ? nil : NSStringFromClass([[self.features objectAtIndex:0] class]);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ features %d. %@ %@", [self class], [self.features count], [self.featureInterval class], self.featureInterval];
}

- (BOOL)isNonNegativeDataSet {
    return self.minScore >= 0;
}
@end