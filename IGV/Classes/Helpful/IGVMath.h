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


#import <Foundation/Foundation.h>

#define ARC4RANDOM_MAX (0x100000000)

@interface IGVMath : NSObject

+ (IGVMath *)sharedIGVMath;

+ (CGFloat)degrees:(CGFloat)radians;

+ (CGFloat)radians:(CGFloat)degrees;

+ (float)clampValue:(float)value lower:(float)lower upper:(float)upper;

+ (float)saturate:(float)value;

+ (float)smoothStepWithValue:(float)value lower:(float)lower upper:(float)upper;

+ (float)interpolateWithValue:(float)value from:(float)from to:(float)to;

+ (float)modWithValue:(float)value divisor:(float)divisor;

+ (float)repeatValue:(float)value frequency:(float)frequency;

+ (float)stepWithValue:(float)value edge:(float)edge;

+ (float)pulseWithValue:(float)value leadingEdge:(float)leadingEdge trailingEdge:(float)trailingEdge;

+ (float)sign:(float)f;

+ (double)sinusoid:(double)d;

+ (CGRect)rectWithOrigin:(CGPoint)aOrigin size:(CGSize)aSize;

+ (CGRect)rectWithCenter:(CGPoint)center size:(CGSize)size;

+ (NSUInteger)percentileForArray:(NSUInteger *)array size:(int)size percentile:(float)percentile;
@end