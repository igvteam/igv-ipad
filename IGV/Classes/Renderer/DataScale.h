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

@class FeatureList;

@interface DataScale : NSObject
- (id)initWithMin:(float)min max:(float)max;
@property(nonatomic, assign) float min;
@property(nonatomic, assign) float yBase;
@property(nonatomic, assign) float max;
@property(nonatomic, assign) BOOL logScale;
- (CGFloat)range;
- (CGFloat)yBaselinePointsWithRenderSurface:(CGRect)renderSurface;
+ (DataScale *)dataScaleWithMin:(CGFloat)min max:(CGFloat)max;

- (BOOL)trivialRejectFeatureList:(FeatureList *)featureList;
- (CGFloat)clipValue:(CGFloat)value nonNegativeDataSet:(BOOL)nonNegativeDataSet;
+ (CGFloat)clipValue:(CGFloat)value low:(CGFloat)low high:(CGFloat)high;
@end