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
//  BAMRecord.h
//  samtools
//
//  Created by James Robinson on 8/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "bam.h"

@class AlignmentBlock;
@class AlignmentBlockItem;

@interface Alignment : NSObject
-(id)initWithStructure: (const bam1_t *)b;
@property(nonatomic, retain) NSMutableString *cigar;
@property(nonatomic, retain) NSMutableArray *alignmentBlocks;
@property(nonatomic) long long int start;
@property(nonatomic) long long int end;
@property(nonatomic) BOOL negativeStrand;
@property(nonatomic) BOOL unmapped;
@property(nonatomic, assign) uint8_t quality;
@property(nonatomic, assign) char gapLineStyle;
-(uint8_t *)qualities;
-(char *)bases;
-(long long int)length;

- (AlignmentBlockItem *)alignmentBlockItemAtLocation:(long long int)location;

- (BOOL)bboxHitTest:(long long int)value;
+(float)alphaFromQuality:(u_int8_t) quality;

+ (double)mismatchSearchWindow;
@end
