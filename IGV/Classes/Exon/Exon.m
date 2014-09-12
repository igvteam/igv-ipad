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
//  Exon.m
//  IGV
//
//  Created by Douglass Turner on 2/28/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import "Exon.h"
#import "IGVContext.h"

@implementation Exon

@synthesize start = _start;
@synthesize end = _end;

- (void) dealloc {

    [super dealloc];
}

- (id)initWithStart:(long long int)start end:(long long int)end {

    self = [super init];

    if (nil != self) {

        self.start = start;
        self.end = end;
    }

    return self;
}

- (long long int)length {

    return 1 + (self.end - self.start);
}

- (CGRect)featureTileForFeatureSurface:(CGRect)featureSurface pointsPerBase:(double)pointsPerBase {

    CGFloat x     = pointsPerBase * ((CGFloat)self.start - (NSInteger)[IGVContext sharedIGVContext].start);
    CGFloat width = pointsPerBase * ((CGFloat)[self length]);

    if (width < 1.0) {

        x = floorf(x);
        width = 1.0;
    }

    return CGRectMake(x, CGRectGetMinY(featureSurface), width, CGRectGetHeight(featureSurface));
 }

- (NSString *)description {

    return [NSString stringWithFormat:@"%@ start %lld end %lld length %lld", [self class], self.start, self.end, [self length]];
}

@end
