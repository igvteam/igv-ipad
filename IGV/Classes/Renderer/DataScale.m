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
// Created by jrobinso on 7/20/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "DataScale.h"
#import "FeatureList.h"

@interface DataScale ()
- (id)initWithMin:(float)min yBase:(float)yBase max:(float)max logScale:(BOOL)logScale;
@end

@interface DataScale ()
@end

@implementation DataScale

@synthesize min = _min;
@synthesize yBase = _yBase;
@synthesize max = _max;
@synthesize logScale = _logScale;

- (id)initWithMin:(float)min yBase:(float)yBase max:(float)max logScale:(BOOL)logScale {

    self = [self init];

    if (nil != self) {
        self.min = min;
        self.yBase = yBase;
        self.max = max;
        self.logScale = logScale;

    }

    return self;
}

- (id)initWithMin:(float)min max:(float)max {

    self = [self initWithMin:min
                       yBase:(min < 0) ? 0 : min
                         max:max
                    logScale:NO];

    return self;
}

- (CGFloat)range {
    return fabsf(self.max - self.min);
}

- (CGFloat)yBaselinePointsWithRenderSurface:(CGRect)renderSurface {

    CGFloat yBaselinePoints;

    if (self.min < 0) {
        yBaselinePoints = (fabsf(self.max)/[self range] * CGRectGetHeight(renderSurface)) + CGRectGetMinY(renderSurface);
    } else {
        yBaselinePoints = CGRectGetMaxY(renderSurface);
    }

    return yBaselinePoints;
}

- (BOOL)trivialRejectFeatureList:(FeatureList *)featureList {

    return  (featureList.maxScore < self.min || featureList.minScore > self.max) ? YES : NO;
}

- (CGFloat)clipValue:(CGFloat)value nonNegativeDataSet:(BOOL)nonNegativeDataSet {

    if (nonNegativeDataSet) {
        return [DataScale clipValue:value low:self.min high:self.max];
    }

    if (value >= 0) {

        if (self.max < 0) {

            return 0;
        } else {

            return [DataScale clipValue:value low:0 high:self.max];
        }

    } else {

        if (self.min > 0) {

            return 0;
        } else {

            // invert sense of comparison then invert the returned result.
            return -([DataScale clipValue:-value low:0 high:-(self.min)]);
        }

    }
}

+ (CGFloat)clipValue:(CGFloat)value low:(CGFloat)low high:(CGFloat)high {

    // values below lower threshold are 0
    if (value < low) return 0;

    // values above upper threshold fill entire track
    CGFloat range = high - low;
    if (value > high) return range;

    // values withing range are clipped to the lower threshold
    return MIN(value, value - low);
}

+ (DataScale *)dataScaleWithMin:(CGFloat)min max:(CGFloat)max {

    return [[[DataScale alloc] initWithMin:min max:max] autorelease];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ max %.3f yBase %.3f min %.3f", [self class], self.max, self.yBase, self.min];
}
@end