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

#import <Foundation/Foundation.h>

@class LittleEndianByteBuffer;


@interface BWHeader : NSObject
@property(nonatomic) short bwVersion;
@property(nonatomic) short nZoomLevels;
@property(nonatomic) long long int chromTreeOffset;
@property(nonatomic) long long int fullDataOffset;  //Offset to main (unzoomed) data.  Points specifically to the dataCount.
@property(nonatomic) long long int fullIndexOffset;
@property(nonatomic) short fieldCount;
@property(nonatomic) short definedFieldCount;
@property(nonatomic) long long int autoSqlOffset;
@property(nonatomic) long long int totalSummaryOffset;
@property(nonatomic) int uncompressBuffSize;
@property(nonatomic) long long int reserved;

- (BWHeader *)initWithBuffer:(LittleEndianByteBuffer *)byteBuffer;
@end