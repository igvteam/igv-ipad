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
// Created by James Robinson on 1/7/14.
//

#import <Foundation/Foundation.h>
#import "FeatureSource.h"

@class BWHeader;
@class BWTotalSummary;
@class BPTree;
@class RPTree;


typedef void (^NoArgBlock)();

typedef enum {
    BigWig = 1,
    BigBed = 2
} BigWigFileType;

@interface BWReader : NSObject

@property(nonatomic, copy) NSString *path;
@property(nonatomic, assign) NSInteger version;
@property(nonatomic, assign) BOOL littleEndian;
@property(nonatomic, assign) BigWigFileType type;
@property(nonatomic, retain) BWHeader *header;

@property(nonatomic, retain) NSMutableArray *zoomLevelHeaders;

@property(nonatomic, copy) NSString *autoSql;

@property(nonatomic, retain) BWTotalSummary *totalSummary;

@property(nonatomic) int dataCount;

@property(nonatomic, retain) BPTree *chromTree;

@property(nonatomic) long long int filesize;

- (BWReader *)initWithPath:(NSString *)aPath;

- (int)idxForChr:(NSString *)chr;

- (void)loadHeader;

- (RPTree *)rpTreeAtOffset:(long long int)offset;

- (NSData *)loadDataAtOffset:(long long int)fileOffset size:(int)byteCount;
@end