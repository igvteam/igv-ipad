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
// Created by jrobinso on 7/27/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "ChrIndex.h"
#import "FileRange.h"
#import "LittleEndianByteBuffer.h"


@interface ChrIndex ()
- (id)initWithBytes:(LittleEndianByteBuffer *)buffer withError:(NSError **)error;

@end

@implementation ChrIndex {
    int binWidth;
    int longestFeature;
    NSInteger nFeatures;
}
@synthesize name;
@synthesize blocks;


- (void)dealloc {
    self.name = nil;
    self.blocks = nil;
    [super dealloc];
}

+ (id)indexFromBytes:(LittleEndianByteBuffer *)buffer withError:(NSError **)error {
    return [[[self alloc] initWithBytes:buffer withError:error] autorelease];
}

- (id)initWithBytes:(LittleEndianByteBuffer *)buffer withError:(NSError **)error {

    self = [super init];
    if (nil != self) {
        self.name = [buffer nextString];
        binWidth = [buffer nextInt];
        NSInteger nBins = [buffer nextInt];
        longestFeature = [buffer nextInt];

        //largestBlockSize = dis.readInt();
        // largestBlockSize and totalBlockSize are old V3 index values.  largest block size should be 0 for
        // all newer V3 block.

        [buffer nextInt];  //BOOL OLD_V3_INDEX = [buffer nextInt] > 0;
        nFeatures = [buffer nextInt];

        // note the code below accounts for > 60% of the total time to read an index
        self.blocks = [NSMutableArray arrayWithCapacity:nBins];
        long long pos = [buffer nextLong];
        for (int binNumber = 0; binNumber < nBins; binNumber++) {
            long long nextPos = [buffer nextLong];
            int size = (int) (nextPos - pos);
            [self.blocks addObject:[FileRange rangeWithPosition:pos byteCount:size]];
            pos = nextPos;
        }
    }
    return self;
}


- (FileRange *)getRangeOverlapping:(int)start end:(int)end {

    int adjustedPosition = MAX(start - longestFeature, 0);
    NSInteger startBinNumber = adjustedPosition / binWidth;
    if (startBinNumber >= [blocks count]) // are we off the end of the bin list, so return nothing
        return nil;
    else {
        NSUInteger endBinNumber = MIN((end - 1) / binWidth, [blocks count] - 1);

        // By definition alignmentBlocks are adjacent for the liner index.  Combine them into one merged block
        FileRange *startBlock = (FileRange *) [blocks objectAtIndex:startBinNumber];
        long long startPos = startBlock.position;    //alignmentBlocks.get(startBinNumber).getStartPosition();

        FileRange *endBlock = (FileRange *) [blocks objectAtIndex:endBinNumber];
        long long endPos = endBlock.position + endBlock.byteCount;
        int size = (int) (endPos - startPos);

        if (size == 0) {
            return nil;
        } else {
            return [FileRange rangeWithPosition:startPos byteCount:size];
        }
    }
}

// Return the length for the entire chromosomeName
- (FileRange *)getRange {
    if (blocks.count == 0) {
        return nil;
    }
    FileRange *startBlock = (FileRange *) [blocks objectAtIndex:0];
    long long startPos = startBlock.position;

    FileRange *endBlock = (FileRange *) [blocks lastObject];
    long long endPos = endBlock.position + endBlock.byteCount;

    int size =  (int) (endPos - startPos);
    return [FileRange rangeWithPosition:startPos byteCount:size];
}

@end