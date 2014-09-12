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
//  Created by turner on 4/12/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "UntranslatedRegion.h"

BOOL const UntranslatedRegionThickStart = YES;
BOOL const UntranslatedRegionThickEnd = NO;

@implementation UntranslatedRegion

@synthesize thick;

- (id)initWithStart:(long long int)start end:(long long int)end thick:(BOOL)aThick {

    self = [super initWithStart:start end:end];

    if (nil != self) {

        self.thick = aThick;
    }

    return self;

}

- (CGRect)featureTileForFeatureSurface:(CGRect)featureSurface pointsPerBase:(double)pointsPerBase {

    CGRect rect = [super featureTileForFeatureSurface:featureSurface pointsPerBase:pointsPerBase];

    CGRect raw = CGRectInset(rect, -0.5, 0.25 * CGRectGetHeight(rect));
    if (raw.size.width < 1.0) return CGRectIntegral(raw);
    else return raw;

}

//- (NSString *)description {
//
//    return [NSString stringWithFormat:@"%@ %@ start %lld end %lld length %lld", thick ? @"thickStart" : @"thickEnd" , [self class], self.start, self.end, [self length]];
//}

@end