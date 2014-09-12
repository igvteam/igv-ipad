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
// Created by turner on 6/30/13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "ZoomSlider.h"
#import "Logging.h"

CGFloat const kZoomSliderQuantization = 80.0;

@implementation ZoomSlider

-(void)awakeFromNib {

    // rotate slider 180 deg to swap orientation of minify/magnify endpoints when widget is displayed
    self.transform = CGAffineTransformMakeRotation((CGFloat)M_PI);
}

-(CGFloat)valueLogarithmic0to1 {

    double numerPower =  self.value - self.minimumValue;
    double denomPower =  self.maximumValue - self.minimumValue;

    double logarithmic = pow(2, numerPower) / pow(2, denomPower);

    return (CGFloat) logarithmic;
}

-(CGFloat)valueWithLogarithmicValue:(CGFloat)logarithmicValue {

    // solve for linear value corresponding to logarithmic value
    double derived = log2(logarithmicValue * pow(2, (self.maximumValue - self.minimumValue))) + self.minimumValue;

    return (CGFloat)derived;
}

- (void)updateWithLinearScaleFactor:(CGFloat)scaleFactor {

    CGFloat derived = [self valueWithLogarithmicValue:scaleFactor];
    self.value = derived;

}

- (BOOL)isNearMinimumValue {

    CGFloat quanta = (self.maximumValue - self.minimumValue) / kZoomSliderQuantization;
    return self.value - self.minimumValue < quanta;
}

- (BOOL)isNearMaximumValue {
    CGFloat quanta = (self.maximumValue - self.minimumValue) / kZoomSliderQuantization;
    return self.maximumValue - self.value < quanta;
}
@end