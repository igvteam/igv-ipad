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
// Created by James Robinson on 1/10/14.
//

#import "BWZoomDataRecord.h"
#import "LittleEndianByteBuffer.h"


@implementation BWZoomDataRecord {

}


- (BWZoomDataRecord *)initWithBuffer:(LittleEndianByteBuffer *)byteBuffer {

    self = [super init];
    if (nil != self) {

        self.chromId = [byteBuffer nextInt];    // Numerical ID for chromosomeName/contig.
        self.chromStart	= [byteBuffer nextInt]; // Start position (starting with 0).
        self.chromEnd	= [byteBuffer nextInt]; // End of item. Same as chromStart + itemSize in bases.
       
        int validCount	= [byteBuffer nextInt]; // Number of bases for which there is data.
        float minVal = [byteBuffer nextFloat];     // Minimum value in region.
        float maxVal = [byteBuffer nextFloat];     // Maximum value in region.
        float sumData = [byteBuffer nextFloat];	 // Sum of all data in region (one value for each base where there is data).
        float sumSquares	= [byteBuffer nextFloat];  //Sum of squares of all data in region.

        self.mean = validCount == 0 ? 0 : sumData / validCount;

    }

    return self;
}
@end