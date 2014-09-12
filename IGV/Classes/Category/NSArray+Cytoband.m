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
// Created by turner on 3/4/13.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "NSArray+Cytoband.h"
#import "IGVHelpful.h"

@implementation NSArray (Cytoband)

- (long long int)start {

    NSNumber *number = (NSNumber *) [self firstObject];
    return [number longLongValue];
}

- (long long int)end {

    NSNumber *number = (NSNumber *) [self lastObject];
    return [number longLongValue];
}

- (long long int)length {

//    return 1 + [self end] - [self start];
    return [self end] - [self start];
}

- (CGRect)bbox {

    NSArray *first	= [self firstObject];
    NSArray *last	= [self  lastObject];

    CGRect firstRectangle	= [[first firstObject] CGRectValue];
    CGRect lastRectangle	= [[ last firstObject] CGRectValue];

    return CGRectUnion(firstRectangle, lastRectangle);
}

-(NSString *)chromosomeArrayDescription {

    NSString *ss = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:[self start]]];
    NSString *ee = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:[self    end]]];
    NSString *ll = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:[self length]]];

    return [NSString stringWithFormat:@"start %@ end %@ length %@", ss, ee, ll];
}

@end