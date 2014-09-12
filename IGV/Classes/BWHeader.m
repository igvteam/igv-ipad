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

#import "BWHeader.h"
#import "LittleEndianByteBuffer.h"


@implementation BWHeader {

}


- (BWHeader *) initWithBuffer: (LittleEndianByteBuffer *) byteBuffer {

    self = [super init];
    if(nil != self) {
        // Table 5  "Common header for BigWig and BigBed files"
        self.bwVersion = [byteBuffer nextShort];
        self.nZoomLevels = [byteBuffer nextShort];
        self.chromTreeOffset = [byteBuffer nextLong];
        self.fullDataOffset = [byteBuffer nextLong];
        self.fullIndexOffset = [byteBuffer nextLong];
        self.fieldCount = [byteBuffer nextShort];
        self.definedFieldCount = [byteBuffer nextShort];
        self.autoSqlOffset = [byteBuffer nextLong];
        self.totalSummaryOffset = [byteBuffer nextLong];
        self.uncompressBuffSize = [byteBuffer nextInt];
        self.reserved = [byteBuffer nextLong];

    }

    return self;
}

@end