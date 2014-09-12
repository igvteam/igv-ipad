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
//  Created by turner on 1/18/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#define SWAP(a, b) temp=(a); (a)=(b); (b) = temp;

#import "IGVMath.h"

@implementation IGVMath

- (void)dealloc {

    [super dealloc];
}

+(IGVMath *)sharedIGVMath {
    
    static dispatch_once_t pred;
    static IGVMath *shared = nil;
    
    dispatch_once(&pred, ^{
        
        shared = [[IGVMath alloc] init];
    });
    
    return shared;
    
}

#pragma mark -
#pragma mark IGVMath - Utility Methods

+ (CGFloat)degrees:(CGFloat)radians {

    return (CGFloat)(radians * 180.0 / M_PI);
}

+ (CGFloat)radians:(CGFloat)degrees {

    return (CGFloat)(degrees * M_PI / 180.0);
}

+ (float) clampValue:(float)value lower:(float)lower upper:(float)upper {

	if (value < lower) return lower;
	if (value > upper) return upper;

	return value;
}

+ (float) saturate:(float)value {

	return [IGVMath clampValue:value lower:0.0 upper:1.0];
}

+ (float) smoothStepWithValue:(float)value lower:(float)lower upper:(float)upper {

	//	// This implementation from:
	//	// Texture & Modeling A Procedural Approach: http://bit.ly/cguJIQ
	//    // By David S. Ebert et al
	//    // pp. 26-27
	//
	//    if (value < lower) return 0.0;
	//
	//    if (value > upper) return 1.0;
	//
	//	// Normalize to 0:1
	//    value = (value - lower)/(upper - lower);

	value = [IGVMath saturate:(value - lower) / (upper - lower)];

    return (value * value * (3.0 - 2.0 * value));

}

+ (float) interpolateWithValue:(float)value from:(float)from to:(float)to {

    return (1. - value) * from + value * to;
}

+ (float) modWithValue:(float)value divisor:(float)divisor {

	int n = (int)(value / divisor);

	value -= n * divisor;
	if (value < 0) value += divisor;

	return value;
}

+ (float) repeatValue:(float)value frequency:(float)frequency {

	return [IGVMath modWithValue:value * frequency divisor:1.0];

}

+ (float) stepWithValue:(float)value edge:(float)edge {

	return (value < edge) ? 0.0 : 1.0;

}

+ (float) pulseWithValue:(float)value leadingEdge:(float)leadingEdge trailingEdge:(float)trailingEdge {

	float  stepLeading = [IGVMath stepWithValue:value edge:leadingEdge];
	float stepTrailing = [IGVMath stepWithValue:value edge:trailingEdge];

	return stepLeading - stepTrailing;

}

+ (float) sign:(float)f {

	if (f < 0.0) return -1.0;

	return 1.0;
}

+ (double)sinusoid:(double)d {

    double radians = 2.0 * M_PI * d;

    return sin(radians);
}

+ (CGRect)rectWithOrigin:(CGPoint)aOrigin size:(CGSize)aSize {

    return CGRectMake(aOrigin.x, aOrigin.y, aSize.width, aSize.height);
}

+ (CGRect)rectWithCenter:(CGPoint)center size:(CGSize)size {

    CGSize halfSize = CGSizeMake(size.width/2.0, size.height/2.0);

    return CGRectMake(center.x - halfSize.width, center.y - halfSize.height, size.width, size.height);
}

// From numerical recipes in C, 1992 edition (public domain)
+ (NSUInteger) percentileForArray:(NSUInteger *)array size:(int)size percentile:(float)percentile {

    int k = (int) ((percentile * size) / 100);

    // Copy array as it will be sorted
    NSUInteger *arr = malloc((size_t) (size * sizeof(NSUInteger)));
    memcpy(arr, array, size * sizeof(NSUInteger));

    int i,ir,j,l,mid;
    NSUInteger a,temp;

    l=1;
    ir= size-1;

    NSUInteger ret = 0;

    while(YES) {
        if (ir <= l+1) {        // Active partition contains 1 or 2 elements
            if (ir == l+1 && arr[ir] < arr[l]) {    // Case of 2 elements
                SWAP(arr[l], arr[ir]);
            }
            ret = arr[k];
            break;
        }  else {
            mid = (l+ir) >> 1;
            SWAP(arr[mid], arr[l+1]);
            if (arr[l] > arr[ir]) {
                SWAP(arr[l], arr[ir]);
            }
            if (arr[l+1] > arr[ir]) {
                SWAP(arr[l+1], arr[ir]);
            }
            if (arr[l] > arr[l+1]) {
                SWAP(arr[l], arr[l+1]);
            }
            i=l+1;
            j=ir;
            a=arr[l+1];
            while(YES) {
                do i++; while(arr[i] < a);
                do j--; while(arr[j] > a);
                if (j < i) break;
                SWAP(arr[i], arr[j]);
            }
            arr[l+1] = arr[j];
            arr[j] = a;
            if (j >= k) ir = j-1;
            if (j <= k) l = i;
        }

    }


    free(arr);
    return ret;

}

@end