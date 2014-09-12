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
//  ExtendedFeature.h
//  IGV
//
//  Created by Douglass Turner on 2/27/12.
//  Copyright (c) 2012 Home. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LabeledFeature.h"

//extern BOOL const FeatureStrandPositive;
//extern BOOL const FeatureStrandNegative;

typedef enum {
    FeatureStrandTypeNone = 1,
    FeatureStrandTypePositive = 2,
    FeatureStrandTypeNegative = 4
} FeatureStrandType;

@interface ExtendedFeature : LabeledFeature
- (id)initWithStart:(long long int)start end:(long long int)end label:(NSString *)label score:(NSInteger)score strand:(FeatureStrandType)strand color:(UIColor *)color;
@property(nonatomic) NSInteger score;
@property(nonatomic, assign) FeatureStrandType strand;
@property(nonatomic, retain) UIColor *color;
@property(nonatomic, retain) NSArray *exons;
+ (FeatureStrandType)strandTypeWithStrandString:(NSString *)strandString;
@end
