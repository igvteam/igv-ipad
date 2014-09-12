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
// Created by turner on 11/18/13.
//

#import "SEGFeature.h"
#import "IGVHelpful.h"

@implementation SEGFeature

- (id)initWithStart:(long long int)start end:(long long int)end value:(CGFloat)value {
    
    self = [super initWithStart:start end:end score:value];
    return self;
}

- (CGFloat)value {
    return self.score;
}

- (BOOL)hitTestWithLocation:(long long int)location width:(double)width {
    double start = location - width/2;
    double end = location + width/2;
    return (self.end >= start && self.start <= end);
}

- (NSString *)description {

    NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];

    NSString *ss  = [numberFormatter stringFromNumber:[NSNumber numberWithLongLong:self.start]];
    NSString *ee = [numberFormatter stringFromNumber:[NSNumber numberWithLongLong:self.end]];
    NSString *ll  = [numberFormatter stringFromNumber:[NSNumber numberWithLongLong:[self length]]];

    return [NSString stringWithFormat:@"%@ start %@ end %@ length %@ value %.3f", [self class], ss, ee, ll, [self value]];
}


@end