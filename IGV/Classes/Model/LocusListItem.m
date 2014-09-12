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
//  Created by turner on 2/8/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "RootContentController.h"
#import "LocusListItem.h"
#import "Logging.h"
#import "IGVContext.h"
#import "Cytoband.h"
#import "GenomeManager.h"
#import "NSArray+Cytoband.h"
#import "IGVHelpful.h"
#import "UIApplication+IGVApplication.h"

@interface LocusListItem ()
- (void)setWithStart:(long long int)start end:(long long int)end;
- (void)setWithLocusCentroid:(long long int)locusCentroid;
- (LocusListItem *)locusListItemWithCentroid:(long long int)centroid length:(long long int)length;
- (NSString *)prettyLocus;
+ (NSString *)stringWithLocusListDefaultsItem:(NSDictionary *)locusListDefaultsItem index:(NSUInteger)index1;
@end

@implementation LocusListItem

@synthesize chromosomeName = _chromosomeName;
@synthesize label = _label;
@synthesize start = _start;
@synthesize end = _end;
@synthesize locusListFormat = _locusListFormat;
@synthesize locus = _locus;
@synthesize genome = _genome;

- (void)dealloc {

    self.chromosomeName = nil;
    self.label = nil;
    self.locus = nil;
    self.genome = nil;

    [super dealloc];
}

- (id)initWithLocus:(NSString *)locus label:(NSString *)label locusListFormat:(LocusListFormat)locusListFormat genomeName:(NSString *)genomeName {

    self = [super init];

    if (nil != self) {

        self.locus = locus;

        self.label  = (nil == label) ? @"." : label;
        self.genome = (nil == genomeName) ? @"." : genomeName;
        
        self.locusListFormat = locusListFormat;

        NSArray *parts = nil;

        switch (self.locusListFormat) {

            case LocusListFormatChrLocusCentroid:
            {

                parts = [locus locusComponentsWithFormat:LocusListFormatChrLocusCentroid];

                self.chromosomeName = [[GenomeManager sharedGenomeManager].chromosomeNames objectForKey:[parts objectAtIndex:0]];

                [self setWithLocusCentroid:[[parts objectAtIndex:1] longLongValue]];

            }
                break;

            case LocusListFormatChrStartEnd:
            {

                parts = [locus locusComponentsWithFormat:LocusListFormatChrStartEnd];

                self.chromosomeName = [[GenomeManager sharedGenomeManager].chromosomeNames objectForKey:[parts objectAtIndex:0]];

                [self setWithStart:[[parts objectAtIndex:1] longLongValue] end:[[parts objectAtIndex:2] longLongValue]];

            }
                break;

            case LocusListFormatChrFullExtent:
            {

                NSString *chromosomeName = [[GenomeManager sharedGenomeManager].chromosomeNames objectForKey:locus];
                NSArray *chromosomeExtent = [[GenomeManager sharedGenomeManager] chromosomeExtentWithChromosomeName:chromosomeName];

                self.chromosomeName = chromosomeName;
                self.start = [chromosomeExtent start];
                self.end   = [chromosomeExtent   end];
            }
                break;

            default:
            {
                self = nil;
            }

        }

    }

    return self;
}

- (void)setWithStart:(long long int)start end:(long long int)end {

    self.start = start;
    self.end   = end;

    double range = (end - start) + 1;

    double centroid = start + end;
    centroid /= 2.0;

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    double rangeThreshold = CGRectGetWidth(rootContentController.rootScrollView.bounds) / kRootScrollViewMaximumPointsPerBases;

    if (range < rangeThreshold) {
        self.start = (long long int)(centroid - (rangeThreshold/2.0));
        self.end   = (long long int)(centroid + (rangeThreshold/2.0));
    }

}

- (void)setWithLocusCentroid:(long long int)locusCentroid {

    double leftBases;
    double rightBases;

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    [rootContentController.rootScrollView locusWithIGVContextStart:[IGVContext sharedIGVContext].start locusStart:&leftBases locusEnd:&rightBases];

    double currentCentroid = (leftBases + rightBases)/2.0;

    double delta = fabs(currentCentroid - leftBases);
    delta *= ([[IGVContext sharedIGVContext] pointsPerBase] / kRootScrollViewMaximumPointsPerBases);

    double ss =  locusCentroid - delta;
    double ee =  locusCentroid + delta;

    if (ss < 0) {

        ee += ss;
        ss = 0;
    } else{

        NSArray *chromosomeExtent = [[GenomeManager sharedGenomeManager] chromosomeExtentWithChromosomeName:self.chromosomeName];
        delta = [chromosomeExtent end] - ee;
        if (delta < 0) {

            ss += delta;
            ee += delta;
        }
    }

    self.start = (long long int)ss;
    self.end   = (long long int)ee;
}

- (long long int)length {
    return self.end - self.start;
}

- (long long int)centroid {
    return (self.start + self.end)/2;
}

- (LocusListItem *)locusListItemWithScaleFactor:(CGFloat)scaleFactor {

    double length = scaleFactor * [self length];

    NSArray *chromosomeExtent = [[GenomeManager sharedGenomeManager] chromosomeExtentWithChromosomeName:self.chromosomeName];

    if (length > [chromosomeExtent length]) {
        return nil;
    }

    if (scaleFactor < 1.0) {

        if (kRootScrollViewMaximumPointsPerBases - [[IGVContext sharedIGVContext] pointsPerBase] < 2.0) {
            return nil;
        }
    }

    return [self locusListItemWithCentroid:[self centroid] length:(long long int)length];
}

- (LocusListItem *)locusListItemWithLength:(long long int)length {
    return [self locusListItemWithCentroid:[self centroid] length:length];
}

- (LocusListItem *)locusListItemWithCentroid:(long long int)centroid length:(long long int)length {
    return [LocusListItem locusWithChromosome:self.chromosomeName centroid:(NSUInteger) centroid length:(NSUInteger) length genomeName:self.genome];
}

+ (LocusListItem *)locusWithChromosome:(NSString *)chromosome centroid:(long long int)centroid length:(long long int)length genomeName:(NSString *)genomeName {

    NSString *chromosomeName = [[GenomeManager sharedGenomeManager].chromosomeNames objectForKey:chromosome];
    NSArray *chromosomeExtent = [[GenomeManager sharedGenomeManager] chromosomeExtentWithChromosomeName:chromosomeName];

    if (fabs(length - [chromosomeExtent length]) < 2) {
        return [[[LocusListItem alloc] initWithLocus:chromosome label:nil locusListFormat:LocusListFormatChrFullExtent genomeName:genomeName] autorelease];
    }

    CGFloat halfWidth = 0.5 * length;
    double ss = centroid - halfWidth;
    double ee = centroid + halfWidth;

    NSNumber *ds = (ss < [chromosomeExtent start]) ? [NSNumber numberWithDouble:(ss - [chromosomeExtent start])] : nil;
    NSNumber *de = (ee > [chromosomeExtent   end]) ? [NSNumber numberWithDouble:(ee - [chromosomeExtent   end])] : nil;

    NSNumber *delta = nil;

    if (nil != ds) {
        delta = ds;
    }

    if (nil != de) {
        if (nil == delta) {
            delta = de;
        } else if (fabs([de doubleValue]) > fabs([ds doubleValue])) {
            delta = de;
        }
    }

    long long int scaledStart;
    long long int scaledEnd;

    if (delta == ds && nil != ds) {
        scaledStart = [chromosomeExtent start];
        scaledEnd   = (long long int)(ee - [ds doubleValue]);
    } else if (delta == de && nil != de) {

        scaledEnd   = [chromosomeExtent end];
        scaledStart = (long long int)(ss - [de doubleValue]);
    } else {
        scaledStart = (long long int)ss;
        scaledEnd   = (long long int)ee;
    }

    LocusListItem *locusListItem = [[[LocusListItem alloc] initWithLocus:[NSString stringWithFormat:@"%@:%lld-%lld", chromosome, scaledStart, scaledEnd]
                                                                   label:nil
                                                         locusListFormat:LocusListFormatChrStartEnd
                                                              genomeName:genomeName] autorelease];

    return locusListItem;
}

+ (LocusListItem *)locusWithChromosome:(NSString *)chromosome centroid:(long long int)centroid halfWidth:(long long int)halfWidth genomeName:(NSString *)genomeName {
    return [LocusListItem locusWithChromosome:chromosome centroid:centroid length:(2 * halfWidth) genomeName:genomeName];
}

#pragma mark - TableViewCell helper methods

- (NSString *)tableViewCellLabel {
    return ([self.label isEqualToString:@""]) ? [self prettyLocus] : self.label;
}

- (NSString *)tableViewCellLocus {
    return ([self.label isEqualToString:@""]) ? @"" : [self prettyLocus];
}

- (NSString *)prettyLocus {
    NSString *s = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:self.start]];
    NSString *e = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:  self.end]];
    NSString *prettyLocus = [NSString stringWithFormat:@"%@:%@-%@", self.chromosomeName, s, e];
    return prettyLocus;
}

#pragma mark - NSUserDefaults helper methods

- (NSDictionary *)locusListDefaultsItem {

    return [NSDictionary dictionaryWithObject:self.label forKey:[self userDefaultsKey]];
}

- (NSString *)userDefaultsKey {
    return [NSString stringWithFormat:@"%@#%@", self.genome, self.locus];
}

+ (NSString *)labelWithLocusListDefaultsItem:(NSDictionary *)locusListDefaultsItem {

    NSString *key = [[locusListDefaultsItem allKeys] objectAtIndex:0];
    return [locusListDefaultsItem objectForKey:key];
}

+ (NSString *)locusWithLocusListDefaultsItem:(NSDictionary *)locusListDefaultsItem {

    return [self stringWithLocusListDefaultsItem:locusListDefaultsItem index:1];
}

+ (NSString *)genomeWithLocusListDefaultsItem:(NSDictionary *)locusListDefaultsItem {

    return [self stringWithLocusListDefaultsItem:locusListDefaultsItem index:0];
}

+ (NSString *)stringWithLocusListDefaultsItem:(NSDictionary *)locusListDefaultsItem index:(NSUInteger)index {

    NSString *key = [[locusListDefaultsItem allKeys] objectAtIndex:0];
    NSArray *parts = [key componentsSeparatedByString:@"#"];

    return [parts objectAtIndex:index];
}

- (NSString *)description {

    NSString *ss = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:     self.start]];
    NSString *ee = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:       self.end]];
    NSString *ll = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:[self length]]];

    NSString *locusFormatString = [IGVHelpful locusListItemFormatName:self.locusListFormat];
//    return [NSString stringWithFormat:@"%@ start %@ end %@ length %@ chr %@ format %@", [self class], ss, ee, ll, self.chromosomeName, locusFormatString];
    return [NSString stringWithFormat:@"%@ start %@ length %@", [self class], ss, ll];
}

+ (LocusListItem *)locusListItemWithChromosomeName:(NSString *)chromosomeName start:(long long int)start end:(long long int)end genomeName:(NSString *)genomeName {

    NSString *locus = [NSString stringWithFormat:@"%@:%lld-%lld", chromosomeName, start, end];
    LocusListItem *locusListItem = [[[LocusListItem alloc] initWithLocus:locus
                                                                   label:nil
                                                         locusListFormat:[locus format]
                                                              genomeName:genomeName] autorelease];


    return locusListItem;
}

- (LocusListItem *)locusListItemWithCentroidPercentage:(CGFloat)centroidPercentage {

    NSArray *chromosomeExtent = [[GenomeManager sharedGenomeManager] chromosomeExtentWithChromosomeName:self.chromosomeName];
    double ss = [chromosomeExtent start];
    double ee = [chromosomeExtent   end];
    double locusListItemCentroid = (1.0 - centroidPercentage) * ss + centroidPercentage * ee;

    return [self locusListItemWithCentroid:(long long int)locusListItemCentroid length:[self length]];
}
@end

