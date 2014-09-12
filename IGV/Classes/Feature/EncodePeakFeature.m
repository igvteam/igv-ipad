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
// Created by turner on 1/31/14.
//

#import "EncodePeakFeature.h"
#import "IGVHelpful.h"

@interface EncodePeakFeature ()
@property(nonatomic) double value;
@end

@implementation EncodePeakFeature

@synthesize value = _value;

- (id)initWithStart:(long long int)start end:(long long int)end name:(NSString *)name score:(NSInteger)score strand:(FeatureStrandType)strand value:(double)value {

    self = [super initWithStart:start end:end label:name score:score strand:strand color:nil];
    if (nil != self) {
        self.value = value;        
    }
    return self;
}

- (NSString *)name {
    return self.label;
}

- (NSString *)description {

    NSString *score = (-1 == self.score) ? @"*" : [NSString stringWithFormat:@"%d", self.score];

    NSString *strand = nil;

    switch (self.strand) {

        case FeatureStrandTypeNone:
            strand = @".";
            break;

        case FeatureStrandTypePositive:
            strand = @"+";
            break;

        case FeatureStrandTypeNegative:
            strand = @"-";
            break;

        default: strand = @".";

    }

    NSString *ss = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:self.start]];
    NSString *ll = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:[self length]]];

    return [NSString stringWithFormat:@"%@ start %@ length %@ name %@ score %@ strand %@ value %f.", self, ss, ll, [self name], score, strand, self.value];
}

@end