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
// Created by James Robinson on 1/8/14.
//

#import "BWTotalSummary.h"
#import "LittleEndianByteBuffer.h"


@implementation BWTotalSummary {

}

- (BWTotalSummary *)init {

    self = [super init];
    if (nil != self) {
        self.basesCovered = 0;
        self.minVal = 0;
        self.maxVal = 0;
        self.sumData = 0;
        self.sumSquares = 0;
        self.mean = 0;;
        self.stddev = 0;
    }

    return self;
}

- (BWTotalSummary *)initWithBuffer:(LittleEndianByteBuffer *)byteBuffer {

    self = [super init];
    if (nil != self) {

        self.basesCovered = [byteBuffer nextLong];
        self.minVal = [byteBuffer nextDouble];
        self.maxVal = [byteBuffer nextDouble];
        self.sumData = [byteBuffer nextDouble];
        self.sumSquares = [byteBuffer nextDouble];

        [self computeStats];

    }

    return self;
}

- (void)computeStats {
    if (self.basesCovered > 0) {
            self.mean = self.sumData / self.basesCovered;
            long long int n = self.basesCovered;
            self.stddev = sqrt((self.sumSquares - (self.sumData / n) * self.sumData) / (n - 1));
        }
}

- (void) updateStatsWithMin: (double) min max: (double) max sum: (double) sum sumSquares: (double) sumSquares count: (int) count {

    _basesCovered += count;
    _sumData += sum;
    _sumSquares += sumSquares;
    _minVal = MIN(_minVal, min);
    _maxVal = MAX(_maxVal, max);

    [self computeStats];

}
@end