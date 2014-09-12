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
//  SelectiveScaleAxisView.m
//  ChromosomeVisualizer
//
//  Created by turner on 10/26/09.
//  Copyright 2009 Douglass Turner Consulting. All rights reserved.
//

#import "SelectiveScaleAxisView.h"

NSString * const      EISSelectiveScaleAxisViewAxisX         =   @"EISSelectiveScaleAxisViewAxisX";
NSString * const      EISSelectiveScaleAxisViewAxisY         =   @"EISSelectiveScaleAxisViewAxisY";
NSString * const      EISSelectiveScaleAxisViewAxisXAxisY   =   @"EISSelectiveScaleAxisViewAxisXAxisY";

@interface SelectiveScaleAxisView ()


@end

@implementation SelectiveScaleAxisView

@synthesize scaleAxis;

- (void)dealloc {

    self.scaleAxis = nil;

    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if ((self = [super initWithCoder:aDecoder])) {
        
        self.scaleAxis = EISSelectiveScaleAxisViewAxisXAxisY;
        
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)aFrame scaleAxis:(NSString *)aScaleAxis {
    
    self = [super initWithFrame:aFrame];
    
    if (nil != self) {
        
        self.scaleAxis = aScaleAxis;
        
    } // if (nil != self)
    
    return self;
    
}

- (id)initWithFrame:(CGRect)aFrame {

    self = [super initWithFrame:aFrame];

    if (nil != self) {
        self.scaleAxis = EISSelectiveScaleAxisViewAxisXAxisY;
    }

    return self;

}

// t =  [ sx 0 0 sy 0  0 ]
// t = [  a b c d tx ty ]
- (void)setTransform:(CGAffineTransform)newValue {

    if ([self.scaleAxis isEqualToString:EISSelectiveScaleAxisViewAxisX]) {
        newValue.d = 1.0;
    }

    if ([self.scaleAxis isEqualToString:EISSelectiveScaleAxisViewAxisY]) {
        newValue.a = 1.0;
    }
	
	[super setTransform:newValue];	
	
}

@end
