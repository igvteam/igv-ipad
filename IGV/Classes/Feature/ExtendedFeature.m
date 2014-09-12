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
//  ExtendedFeature.m
//  IGV
//
//  Created by Douglass Turner on 2/27/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "ExtendedFeature.h"
#import "IGVHelpful.h"

NSString *const FeatureStrandTypePositiveString = @"+";
NSString *const FeatureStrandTypeNegativeString = @"-";
NSString *const FeatureStrandTypeNoneString = @".";

@implementation ExtendedFeature

@synthesize score = _score;
@synthesize strand = _strand;
@synthesize color = _color;
@synthesize exons = _exons;

- (void)dealloc {

    self.color = nil;
    self.exons = nil;

    [super dealloc];
}

- (id)initWithStart:(long long int)start end:(long long int)end label:(NSString *)label score:(NSInteger)score strand:(FeatureStrandType)strand color:(UIColor *)color {

    self = [super initWithStart:start end:end label:label];

    if (nil != self) {

        self.score = score;
        self.strand = strand;
        self.color = color;
    }

    return self;
}


+ (FeatureStrandType)strandTypeWithStrandString:(NSString *)strandString {

    if ([strandString isEqualToString:FeatureStrandTypePositiveString]) return FeatureStrandTypePositive;
    if ([strandString isEqualToString:FeatureStrandTypeNegativeString]) return FeatureStrandTypeNegative;
    if ([strandString isEqualToString:FeatureStrandTypeNoneString]    ) return FeatureStrandTypeNone;

    return FeatureStrandTypeNone;

}

@end
