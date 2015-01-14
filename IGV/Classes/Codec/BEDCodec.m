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
//  Created by turner on 2/28/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "BEDCodec.h"
#import "ExtendedFeature.h"
#import "Exon.h"
#import "UntranslatedRegion.h"
#import "IGVHelpful.h"
#import "GenomeManager.h"

@interface BEDCodec ()
- (NSArray *)decodeExonsWithStart:(long long int)start thickStart:(long long int)thickStart thickEnd:(long long int)thickEnd tokens:(NSArray *)aTokens error:(NSError **)error;
+ (UIColor *)colorWithRGBString:(NSString *)rgbString error:(NSError **)error;
@end

@implementation BEDCodec

- (Feature *)decodeLine:(NSString *)aLine chromosome:(NSString **)chromosome error:(NSError **)error {

    NSMutableArray *tokens = [NSMutableArray arrayWithArray:[aLine componentsSeparatedByString:@"\t"]];

    if (3 > [tokens count]) {
        if (error) *error = [IGVHelpful errorWithDetailString:[NSString stringWithFormat:@"%@. token count %d < 3", [self class], [tokens count]]];
        return nil;
    }

    *chromosome = [[GenomeManager sharedGenomeManager] chromosomeAliasForString:[tokens objectAtIndex:0]];

    NSUInteger index;

    index = 1;
    long long int start = [[tokens objectAtIndex:index] longLongValue];

    index = 2;
    long long int end = [[tokens objectAtIndex:index] longLongValue];

    if (start == end) {
        ++end;
    }

    if (end < start) {

        if (error) *error = [IGVHelpful errorWithDetailString:[NSString stringWithFormat:@"%@. end %lld is less than start %lld", [self class], end, start]];
        return nil;
    }

    long long int featureStart = start;
    long long int featureEnd = end;

    if ([tokens count] < 4) {
        return [[[LabeledFeature alloc] initWithStart:featureStart end:featureEnd label:nil] autorelease];
    }

    NSString *label = [tokens objectAtIndex:3];
    if ([tokens count] < 5) {
        return [[[LabeledFeature alloc] initWithStart:featureStart end:featureEnd label:label] autorelease];
    }








//    return [[[LabeledFeature alloc] initWithStart:featureStart end:featureEnd label:label] autorelease];











    index = 4;
    NSInteger score = [[tokens objectAtIndex:index] integerValue];

    if ([tokens count] < 6) {
        return [[[ExtendedFeature alloc] initWithStart:featureStart end:featureEnd label:label score:score strand:FeatureStrandTypeNone color:nil] autorelease];
    }

    index = 5;
    FeatureStrandType strand = [ExtendedFeature strandTypeWithStrandString:[tokens objectAtIndex:index]];

    if ([tokens count] < 9) {
        return [[[ExtendedFeature alloc] initWithStart:featureStart end:featureEnd label:label score:score strand:strand color:nil] autorelease];
    }

    index = 6;
    long long int thickStart = [[tokens objectAtIndex:index] longLongValue];

    index = 7;
    long long int thickEnd = [[tokens objectAtIndex:index] longLongValue];

    index = 8;
    UIColor *color = [BEDCodec colorWithRGBString:[tokens objectAtIndex:index] error:error];
    if (nil == color) {

        if (*error) {
            return nil;
        }
    }

    ExtendedFeature *extendedFeature = [[[ExtendedFeature alloc] initWithStart:featureStart end:featureEnd label:label score:score strand:strand color:color] autorelease];

    if (tokens.count > 10) {
        extendedFeature.exons = [self decodeExonsWithStart:start thickStart:thickStart thickEnd:thickEnd tokens:tokens error:error];
        if (*error) {
            return nil;
        }
    }

    return extendedFeature;
}

- (NSArray *)decodeExonsWithStart:(long long int)start thickStart:(long long int)thickStart thickEnd:(long long int)thickEnd tokens:(NSArray *)aTokens error:(NSError **)error {

    NSScanner *scanner;
    NSUInteger index;
    long long int count;

    // count
    index = 9;
    count = [[aTokens objectAtIndex:index] longLongValue];

    scanner = [NSScanner scannerWithString:[aTokens objectAtIndex:10]];
    NSMutableArray *sizes = [NSMutableArray array];

    while (![scanner isAtEnd]) {

        NSString *string;
        [scanner scanUpToString:@"," intoString:&string];
        [scanner scanString:@"," intoString:NULL];
        [sizes addObject:string];
    }

    if (count != [sizes count]) {

        if (error) *error = [IGVHelpful errorWithDetailString:[NSString stringWithFormat:@"%@. count != [sizes count]. %lld != %d", [self class], count, [sizes count]]];
        return nil;
    }

    scanner = [NSScanner scannerWithString:[aTokens objectAtIndex:11]];
    NSMutableArray *starts = [NSMutableArray array];

    while (![scanner isAtEnd]) {

        NSString *string;
        [scanner scanUpToString:@"," intoString:&string];
        [scanner scanString:@"," intoString:NULL];
        [starts addObject:string];
    }

    if (count != [starts count]) {

        if (error) *error = [IGVHelpful errorWithDetailString:[NSString stringWithFormat:@"%@. count != [starts count]. %lld != %d", [self class], count, [starts count]]];
        return nil;
    }

    NSMutableArray *exons = [NSMutableArray array];

    @autoreleasepool {

        for (NSUInteger i = 0; i < count; i++) {

            long long int exonStartOffset = [[starts objectAtIndex:i] longLongValue];
            long long int exonLength      = [[sizes  objectAtIndex:i] longLongValue];

            long long int exonStart = start + exonStartOffset;
            long long int exonEnd = exonStart + exonLength - 1;

            if (thickStart > exonStart && thickStart < exonEnd) {

                [exons addObject:[[[UntranslatedRegion alloc] initWithStart:(1 + exonStart) end:(1 + thickStart) thick:UntranslatedRegionThickStart] autorelease]];
                [exons addObject:[[[Exon alloc] initWithStart:(1 + thickStart) end:(1 + exonEnd)] autorelease]];

            } else if (thickEnd > exonStart && thickEnd < exonEnd) {

                [exons addObject:[[[Exon alloc] initWithStart:(1 + exonStart) end:(1 + thickEnd)] autorelease]];
                [exons addObject:[[[UntranslatedRegion alloc] initWithStart:(1 + thickEnd) end:(1 + exonEnd) thick:UntranslatedRegionThickEnd] autorelease]];
            } else {

                [exons addObject:[[[Exon alloc] initWithStart:(1 + exonStart) end:(1 + exonEnd)] autorelease]];
            }

        }

    }


    return exons;
}

+ (UIColor *)colorWithRGBString:(NSString *)rgbString error:(NSError **)error {

    NSArray *rgb = [rgbString componentsSeparatedByString:@","];
    if (nil == rgb) {

        if (error) *error = [IGVHelpful errorWithDetailString:[NSString stringWithFormat:@"%@ is not a valid color specification", rgbString]];
        return nil;
    }

    // TODO - dat - ignoring single character "."
    if (1 == [rgb count]) {
        return nil;
    }

    CGFloat r = [[rgb objectAtIndex:0] floatValue] / 255.0;
    CGFloat g = [[rgb objectAtIndex:1] floatValue] / 255.0;
    CGFloat b = [[rgb objectAtIndex:2] floatValue] / 255.0;

    return [UIColor colorWithRed:r green:g blue:b alpha:1];
}

+ (NSString *)fileSuffixKey {
    return @"bed";
}

+ (NSString *)indexFileSuffix {
    return @"idx";
}

@end