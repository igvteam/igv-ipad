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
// Created by turner on 5/26/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "NSString+FileURLAndLocusParsing.h"
#import "IGVContext.h"
#import "Cytoband.h"
#import "GenomeManager.h"
#import "NSArray+Cytoband.h"

@implementation NSString (FileURLAndLocusParsing)

- (NSString *)removeHeadTailWhitespace {

    NSString *headWhitespace = @"^\\s+";
    NSString *tailWhitespace = @"\\s+$";

    NSRange range;
    NSString *a;
    NSString *string;

    // Discard head whitespace
    range = [self rangeOfString:headWhitespace options:NSRegularExpressionSearch];
    a = (0 == range.length) ? self : [self stringByReplacingCharactersInRange:range withString:@""];

    // Discard tail whitespace
    range =  [a rangeOfString:tailWhitespace options:NSRegularExpressionSearch];
    string = (0 == range.length) ? a : [a stringByReplacingCharactersInRange:range withString:@""];

    return string;

}

- (LocusListFormat)format {
    return [self formatWithGenomeManager:[GenomeManager sharedGenomeManager]];
}

- (LocusListFormat)formatWithGenomeManager:(GenomeManager *)genomeManager {

    if (nil != [genomeManager.chromosomeNames objectForKey:self]) {

        return LocusListFormatChrFullExtent;
    }

    // Does the string contain at least 1 ":". If not the original string is returned at item 0 in the parts array
    NSArray *parts = [self componentsSeparatedByString:@":"];

    if (1 == [parts count]) {
        return LocusListFormatInvalid;
    }

    NSString *candidateChromosomeName;

    if ([parts count] > 2) {

        NSString *string = [NSString stringWithString:self];
        NSRange rangeOfSubstring = [string rangeOfString:[NSString stringWithFormat:@":%@", [parts objectAtIndex:([parts count] - 1)]]];

        // return only that portion of 'string' up to where '<a href' was found
        candidateChromosomeName = [string substringToIndex:rangeOfSubstring.location];

    } else {

        candidateChromosomeName = [parts objectAtIndex:0];
    }

    if (nil == [genomeManager.chromosomeNames objectForKey:candidateChromosomeName]) {

        return LocusListFormatInvalid;
    }

    NSString *chromosomeName = [genomeManager.chromosomeNames objectForKey:candidateChromosomeName];
    NSArray *chromosomeExtent = [genomeManager chromosomeExtentWithChromosomeName:chromosomeName];

    // In the event that the string has multiple ":" use the last one as the separator between chromosomeName
    // name and start-end
    NSString *remainder = [parts objectAtIndex:([parts count] - 1)];


//    ALog(@"chromosomeName %@ remainder %@", chromosomeName, remainder);

    NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];

    NSNumber *number = [formatter numberFromString:remainder];

    // We have recognized chr:start
    if (nil != number) {

        if ([number longLongValue] < 0 || [number longLongValue] > [chromosomeExtent end]) {
            return LocusListFormatInvalid;
        }

        return LocusListFormatChrLocusCentroid;
    }

    NSArray *more = [remainder componentsSeparatedByString:@"-"];

    NSNumber *start = [formatter numberFromString:(NSString *) [more objectAtIndex:0]];
    if (nil == start) {
        return LocusListFormatInvalid;
    }

    NSNumber *end = [formatter numberFromString:(NSString *) [more objectAtIndex:1]];
    if (nil == end) {
        return LocusListFormatInvalid;
    }

    // start and end are numbers. further checking
    if ([end longLongValue] == 0) {
        return LocusListFormatInvalid;
    }

    if ([start longLongValue] > [end longLongValue]) {
        return LocusListFormatInvalid;
    }

    if ([start longLongValue] < 0 || [end longLongValue] < 0) {
        return LocusListFormatInvalid;
    }

    if ([start longLongValue] > [chromosomeExtent end] || [end longLongValue] > [chromosomeExtent end]) {
        return LocusListFormatInvalid;
    }

    return LocusListFormatChrStartEnd;
}

- (NSArray *)locusComponentsWithFormat:(LocusListFormat)format {

    NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];

    NSArray *parts = [self componentsSeparatedByString:@":"];

    NSString *chr;
    NSString *remainder;

    // There can be a ":" in the chromosomeName name. Handle it.
    if (3 == [parts count]) {

        chr = [NSString stringWithFormat:@"%@%@", [parts objectAtIndex:0], [parts objectAtIndex:1]];
        remainder = [parts objectAtIndex:2];
    } else {

        chr = [parts objectAtIndex:0];
        remainder = [parts objectAtIndex:1];
    }

    if (LocusListFormatChrLocusCentroid == format) {

        NSNumber *start = [formatter numberFromString:remainder];
        return [NSArray arrayWithObjects:chr, start, nil];
    }

    NSNumber *start = [formatter numberFromString:(NSString *)[[remainder componentsSeparatedByString:@"-"] objectAtIndex:0]];
    NSNumber *end = [formatter numberFromString:(NSString *)[[remainder componentsSeparatedByString:@"-"] objectAtIndex:1]];

    return [NSArray arrayWithObjects:chr, start, end, nil];

}

@end