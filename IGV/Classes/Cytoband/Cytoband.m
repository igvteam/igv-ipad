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
//  Cytoband.m
//  ParseCytoband
//
//  Created by turner on 9/9/09.
//  Copyright 2009 Douglass Turner Consulting. All rights reserved.
//

#import "Cytoband.h"
#import "IGVContext.h"
#import "HttpResponse.h"
#import "URLDataLoader.h"
#import "GenomeManager.h"
#import "LocusListItem.h"
#import "Logging.h"

@interface Cytoband ()
@property(nonatomic, retain) NSData *data;
- (void)loadData;

- (NSString *)rawChromosomeNameWithLine:(NSString *)line;
@end

@implementation Cytoband

@synthesize colorNames;
@synthesize chromosomes;
@synthesize data;
@synthesize chromosomeNames = _chromosomeNames;
@synthesize rawChromsomeNames = _rawChromsomeNames;

- (void)dealloc {

    self.colorNames = nil;
    self.chromosomes = nil;
    self.data = nil;
    self.chromosomeNames = nil;
    self.rawChromsomeNames = nil;

    [super dealloc];
}

- (id)initWithPath:(NSString *)path {

    self = [super init];

    if (nil != self) {

        self.data = [NSData dataWithContentsOfURL:[NSURL URLWithString:path]];

        if (nil == self.data) {
            return nil;
        }

        [self loadData];
    }

    return self;

}

- (NSString *)firstChromosomeName {
    return [self chromosomeNameWithLine:[[self dataAsStrings] objectAtIndex:0]];
}

- (NSArray *)chromosomeExtentWithChromosomeName:(NSString *)chromosomeName {

    NSArray *chromosome = [self.chromosomes objectForKey:chromosomeName];

    if (nil == chromosome) {
        return nil;
    }
    else {
        NSArray *chromsomeExtent = [NSArray arrayWithObjects:[[chromosome firstObject] objectAtIndex:0], [[chromosome lastObject] objectAtIndex:1], nil];
        return chromsomeExtent;
    }
}

- (void)loadData {

    self.chromosomes = [NSMutableDictionary dictionary];

    NSArray *lines = [self dataAsStrings];

    for (NSString *line in lines) {

        NSString *chromosomeName = [self chromosomeNameWithLine:line];
        if (nil == chromosomeName) {
            continue;
        }

        if (nil == [self.chromosomes objectForKey:chromosomeName]) {
            [self.chromosomes setObject:[NSMutableArray array] forKey:chromosomeName];
        }

        [[self.chromosomes objectForKey:chromosomeName] addObject:[self chromosomeWithLine:line]];
    }


    NSMutableArray *accumulate = [NSMutableArray array];
    for (NSString *line in lines) {

        NSString *rawChromosomeName = [self rawChromosomeNameWithLine:line];
        if (nil == rawChromosomeName) {
            continue;
        }

        if ([rawChromosomeName isEqualToString:[accumulate lastObject]]) {
            continue;
        }

        [accumulate addObject:rawChromosomeName];
    }

    self.rawChromsomeNames = [accumulate sortedArrayUsingComparator:^(NSString *a, NSString *b) {
        return [a compare:b options:NSNumericSearch];
    }];

    // Create sorted list of chromosomeName names
    __block NSMutableArray *numerical = [NSMutableArray array];
    __block NSMutableArray *alpha = [NSMutableArray array];
    [[self.chromosomes allKeys] enumerateObjectsUsingBlock:^(NSString *chromosome, NSUInteger index, BOOL *ignore){
        if (0 != [chromosome integerValue]) [numerical addObject:chromosome];
        else [alpha addObject:chromosome];
    }];

    [numerical sortUsingComparator:(NSComparator) ^(NSString *a, NSString *b) {
        return [[NSNumber numberWithInteger:[a integerValue]] compare:[NSNumber numberWithInteger:[b integerValue]]];
    }];

    [alpha sortUsingComparator:(NSComparator) ^(NSString *a, NSString *b) {
        return [a compare:b];
    }];

    self.chromosomeNames = [NSMutableArray arrayWithArray:numerical];
    [self.chromosomeNames addObjectsFromArray:alpha];

}

- (NSMutableArray *)chromosomeWithLine:(NSString *)line {

    NSMutableArray *chromosome = [NSMutableArray arrayWithArray:[line componentsSeparatedByString:@"\t"]];
    [chromosome removeObjectAtIndex:0];

    return chromosome;
}

- (NSString *)chromosomeNameWithLine:(NSString *)line {

    NSString *name = [[line componentsSeparatedByString:@"\t"] objectAtIndex:0];
    return [[GenomeManager sharedGenomeManager].chromosomeNames objectForKey:name];
}

- (NSString *)rawChromosomeNameWithLine:(NSString *)line {
    NSString *name = [[line componentsSeparatedByString:@"\t"] objectAtIndex:0];
    return ([[GenomeManager sharedGenomeManager].chromosomeNames objectForKey:name]) ? name : nil;
}

- (NSArray *)dataAsStrings {

    NSString *string = [[[NSString alloc] initWithBytes:[self.data bytes] length:[self.data length] encoding:NSUTF8StringEncoding] autorelease];
    return [string componentsSeparatedByString:@"\n"];

}

- (NSDictionary *)colorNames {

    if (nil == colorNames) {

        // Color dictionary for staining chromosomes
        self.colorNames = [[[NSDictionary alloc] initWithObjectsAndKeys:
                [UIColor redColor], @"acen",
                [UIColor whiteColor], @"stalk",
                [UIColor whiteColor], @"gvar",
                [UIColor whiteColor], @"gneg",
                [UIColor lightGrayColor], @"gpos25",
                [UIColor grayColor], @"gpos50",
                [UIColor darkGrayColor], @"gpos75",
                [UIColor blackColor], @"gpos100",
                nil] autorelease];

    }

    return colorNames;
}

- (NSMutableArray *)rectangleListTemplateForChromosomeName:(NSString *)chromosomeName {

    NSArray *chromosome = [self.chromosomes objectForKey:chromosomeName];

    NSMutableArray *rectangles = [NSMutableArray array];
    for (NSMutableArray *list in chromosome) {

        // Create a unit-height rectangle positioned along the x-axis.
        CGFloat x = [[list objectAtIndex:0] floatValue];
        CGFloat y = 0.0;
        CGFloat width = [[list objectAtIndex:1] floatValue] - x;
        CGFloat height = 1.0;
        NSValue *rectangle = [NSValue valueWithCGRect:CGRectMake(x, y, width, height)];

        // Rectangle color
        NSString *colorName = [list objectAtIndex:3];

        NSArray *coloredRect = [NSArray arrayWithObjects:rectangle, colorName, nil];
        [rectangles addObject:coloredRect];
    }

    return rectangles;
}
@end
