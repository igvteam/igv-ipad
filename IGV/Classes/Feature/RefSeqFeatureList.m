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
// Created by turner on 1/22/13.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "RefSeqFeatureList.h"
#import "IGVHelpful.h"
#import "FeatureInterval.h"

@implementation RefSeqFeatureList

@synthesize refSeqString = _refSeqString;

- (void)dealloc {

    self.refSeqString = nil;
    [super dealloc];
}

- (id)init {

    self = [super initEmptyForChr:@""];
    return self;
}

- (NSString *)refSeqString {

    if (nil == _refSeqString) {
        self.refSeqString = @"";
    }

    return _refSeqString;
}

- (NSString *)description {

    NSString *sl = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithUnsignedInteger:[self.refSeqString length]]];
    NSString *ss = (self.featureInterval.start == LLONG_MIN) ? @"LLONG_MIN" : [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:self.featureInterval.start]];
    NSString *ll = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:[self.featureInterval length]]];

    return [NSString stringWithFormat:@"%@ string %@ interval %@ %@", [self class], sl, ll, ss];
}

@end