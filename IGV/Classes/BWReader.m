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

#import "BWReader.h"
#import "FeatureSource.h"
#import "URLDataLoader.h"
#import "FileRange.h"
#import "IGVHelpful.h"
#import "LittleEndianByteBuffer.h"
#import "HttpResponse.h"
#import "BWHeader.h"
#import "BWZoomLevelHeader.h"
#import "BWTotalSummary.h"
#import "BPTree.h"
#import "RPTree.h"
#import "NSData+GZIP.h"

int const BIGWIG_MAGIC_LTH = 0x888FFC26; // BigWig Magic Low to High
int const BIGWIG_MAGIC_HTL = 0x26FC8F66; // BigWig Magic High to Low
int const BIGBED_MAGIC_LTH = 0x8789F2EB; // BigBed Magic Low to High
int const BIGBED_MAGIC_HTL = 0xEBF28987; // BigBed Magic High to Low
int const BBFILE_HEADER_SIZE = 64;
int const ZOOM_LEVEL_HEADER_SIZE = 24;

@interface BWReader ()
@property(nonatomic, retain) NSMutableDictionary *rpTrees;
@end

@implementation BWReader {

}


- (void)dealloc {

    self.path = nil;
    self.header = nil;
    self.zoomLevelHeaders = nil;
    self.autoSql = nil;
    self.totalSummary = nil;
    self.chromTree = nil;
    self.rpTrees = nil;
    [super dealloc];
}

- (BWReader *)initWithPath:(NSString *)aPath {

    self = [super init];

    if (nil != self) {

        self.path = aPath;
        self.rpTrees = [NSMutableDictionary dictionary];
    }

    return self;
}

- (int)idxForChr:(NSString *)chr {

    if (nil == self.header) {
        [self loadHeader];
    }

    NSNumber *idxNumber = [self.chromTree.dictionary objectForKey:chr];

    if (nil == idxNumber) {
        return -1;
    }
    else {
        return idxNumber.intValue;
    }

}

- (void)loadHeader {

    HttpResponse *response_0 = [URLDataLoader loadDataSynchronousWithPath:self.path forRange:[FileRange rangeWithPosition:0 byteCount:BBFILE_HEADER_SIZE]];

    if ([IGVHelpful errorDetected:response_0.error]) {
        // TODO handle error
        return;
    }

    // Assume low-to-high unless proven otherwise
    self.littleEndian = YES;

    LittleEndianByteBuffer *byteBuffer = [LittleEndianByteBuffer littleEndianByteBufferWithData:response_0.receivedData littleEndian:self.littleEndian];

    int magic = [byteBuffer nextInt];

    if (magic == BIGWIG_MAGIC_LTH) {
        self.type = BigWig;
    }
    else if (magic == BIGBED_MAGIC_LTH) {
        self.type = BigBed;
    }
    else {
        // Try big endian order
        self.littleEndian = NO;

        byteBuffer = [LittleEndianByteBuffer littleEndianByteBufferWithData:response_0.receivedData littleEndian:self.littleEndian];
        magic = [byteBuffer nextInt];
        if (magic == BIGWIG_MAGIC_HTL) {
            self.type = BigWig;
        }
        else if (magic == BIGBED_MAGIC_HTL) {
            self.type = BigBed;
        }
        else {
            // We don't know what this is.
            //TODO return error
        }
    }

    self.header = [[[BWHeader alloc] initWithBuffer:byteBuffer] autorelease];

    // Get content length
    HttpResponse *resp = [URLDataLoader loadHeaderSynchronousWithPath:self.path];
    self.filesize = resp.contentLength;

    // Now load everything up to the data section

    [self loadZoomHeadersAndChrTree];

}

- (void)loadZoomHeadersAndChrTree {


    int startOffset = BBFILE_HEADER_SIZE;
    long long endOffset = self.header.fullDataOffset + 4;   // We'll get the data count now as well (4 bytes)
    int nBytes = (int) (endOffset - startOffset);


    HttpResponse *response_1 = [URLDataLoader loadDataSynchronousWithPath:self.path forRange:[FileRange rangeWithPosition:startOffset byteCount:nBytes]];


    if ([IGVHelpful errorDetected:response_1.error]) {
        // TODO -- handle error
        return;
    }

    LittleEndianByteBuffer *byteBuffer = [LittleEndianByteBuffer littleEndianByteBufferWithData:response_1.receivedData littleEndian:self.littleEndian];

    // Zoom headers
    NSUInteger nZooms = (NSUInteger) self.header.nZoomLevels;
    self.zoomLevelHeaders = [NSMutableArray arrayWithCapacity:nZooms];
    for (int i = 0; i < nZooms; i++) {
        int zoomNumber = nZooms - i;
        BWZoomLevelHeader *zlh = [[[BWZoomLevelHeader alloc] initWithBuffer:byteBuffer index:zoomNumber] autorelease];
        [self.zoomLevelHeaders addObject:zlh];
    }

    // Autosql
    if (self.header.autoSqlOffset > 0) {
        byteBuffer.position = self.header.autoSqlOffset - startOffset;
        self.autoSql = [byteBuffer nextString];
    }

    // Total summary
    if (self.header.totalSummaryOffset > 0) {
        byteBuffer.position = self.header.totalSummaryOffset - startOffset;
        self.totalSummary = [[[BWTotalSummary alloc] initWithBuffer:byteBuffer] autorelease];
    }

    // Chrom data index
    if (self.header.chromTreeOffset > 0) {
        byteBuffer.position = self.header.chromTreeOffset - startOffset;
        self.chromTree = [[[BPTree alloc] initWithBuffer:byteBuffer treeOffset:0] autorelease];
    }
    else {
        // TODO -- this is an error, not expected
    }

    //Finally total data count
    byteBuffer.position = self.header.fullDataOffset - startOffset;
    self.dataCount = [byteBuffer nextInt];

}

- (RPTree *)rpTreeAtOffset:(long long int)offset {

    NSNumber *key = [NSNumber numberWithLongLong:offset];
    RPTree *rpTree = [self.rpTrees objectForKey:key];
    if (nil == rpTree) {
        rpTree = [[[RPTree alloc] initWithOffset:offset filesize:self.filesize path:self.path littleEndian:self.littleEndian] autorelease];
        [rpTree load];
        [self.rpTrees setObject:rpTree forKey:key];
    }

    return rpTree;
}


- (NSData *)loadDataAtOffset:(long long int)fileOffset size:(int)byteCount {

    HttpResponse *response = [URLDataLoader loadDataSynchronousWithPath:self.path forRange:[FileRange rangeWithPosition:fileOffset byteCount:byteCount]];

    // TODO -- handle error

    return response.receivedData;


}

@end