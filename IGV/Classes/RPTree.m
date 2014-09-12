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
// Created by James Robinson on 1/9/14.
//

#import "RPTree.h"
#import "LittleEndianByteBuffer.h"
#import "URLDataLoader.h"
#import "FileRange.h"
#import "HttpResponse.h"
#import "Logging.h"
#import "BufferedReader.h"

int const RPTREE_MAGIC_LTH = 0x2468ACE0;
int const RPTREE_MAGIC_HTL = 0xE0AC6824;
int const RPTREE_HEADER_SIZE = 48;
int const RPTREE_NODE_LEAF_ITEM_SIZE = 32;   // leaf item size
int const RPTREE_NODE_CHILD_ITEM_SIZE = 24;  // child item size
int const BUFFER_SIZE = 512000;     //  buffer


@interface RPTree ()
@property(nonatomic) long long int filesize;
@property(nonatomic) long long int fileOffset;
@property(nonatomic) BOOL littleEndian;
@property(nonatomic, retain) LittleEndianByteBuffer *byteBuffer;
@property(nonatomic, retain) BufferedReader *bufferedReader;
@end

@implementation RPTree {

}


- (void)dealloc {

    self.header = nil;
    self.rootNode = nil;
    self.path = nil;
    self.byteBuffer = nil;
    self.bufferedReader = nil;
    [super dealloc];


}


- (RPTree *)initWithOffset:(long long)fileOffset
                  filesize:(long long)filesize
                      path:(NSString *)path
              littleEndian:(BOOL)littleEndian {

    self = [super init];
    
    if (nil != self) {

        self.filesize = filesize;
        self.fileOffset = fileOffset; // File offset to beginning of tree
        self.path = path;
        self.littleEndian = littleEndian;
        self.bufferedReader = nil;
    }

    return self;
}


- (void)load {

    // Get content length

    self.bufferedReader = [[[BufferedReader alloc] initForPath:self.path
                                                 contentLength:self.filesize
                                                    bufferSize:BUFFER_SIZE] autorelease];

    FileRange *range = [FileRange rangeWithPosition:self.fileOffset
                                          byteCount:RPTREE_HEADER_SIZE];
    
    NSData *data = [self.bufferedReader dataForRange:range];
    
    self.byteBuffer = [LittleEndianByteBuffer littleEndianByteBufferWithData:data
                                                                littleEndian:self.littleEndian];

    long long rootNodeOffset = self.fileOffset + RPTREE_HEADER_SIZE;
    self.rootNode = [self readNodeAtFilePosition:rootNodeOffset];
    // TODO -- rest of tree

}


- (void)findLeafItemsOverlappingChr:(int)chrIdx startBase:(int)startBase endBase:(int)endBase items:(NSMutableArray *)leafItems {

    [self _findLeafItemsOverlappingChr:chrIdx
                             startBase:startBase
                               endBase:endBase
                                  node:self.rootNode
                                 items:leafItems];
}

- (void)_findLeafItemsOverlappingChr:(int)chrIdx
                           startBase:(int)startBase
                             endBase:(int)endBase
                                node:(RPTreeNode *)node
                               items:(NSMutableArray *)leafItems {

    if ([node overlapsChr:chrIdx startBase:startBase endBase:endBase]) {

        NSArray *items = node.items;
        for (RPTItem *item in items) {

            if ([item overlapsChr:chrIdx startBase:startBase endBase:endBase]) {
                if (item.isLeaf) {
                    [leafItems addObject:item];
                }
                else {
                    //ALog(@"%@", item);
                    RPTChildItem *ci = (RPTChildItem *) item;   // I don't like this much
                    RPTreeNode *childNode = ci.childNode;
                    if (nil == childNode) {
                        childNode = [self readNodeAtFilePosition:ci.childOffset];
                        ci.childNode = childNode;
                    }
                    [self _findLeafItemsOverlappingChr:chrIdx startBase:startBase endBase:endBase node:childNode items:leafItems];
                }
            }

        }
    }
}


- (RPTreeNode *)readNodeAtFilePosition:(long long)filePosition {


    id node;

    FileRange *range = [FileRange rangeWithPosition:filePosition byteCount:4];
    NSData *data = [self.bufferedReader dataForRange:range];
    LittleEndianByteBuffer *byteBuffer = [LittleEndianByteBuffer littleEndianByteBufferWithData:data littleEndian:self.littleEndian];
    filePosition += 4;

    u_char type = [byteBuffer nextByte];
    BOOL isLeaf = (type == (u_char) 1) ? YES : NO;

    u_char reserved = [byteBuffer nextByte];
    short count = [byteBuffer nextShort];

    NSMutableArray *items = [NSMutableArray arrayWithCapacity:count];

    // Check available bytes,  refresh if neccessary
    int bytesRequired = count * (isLeaf ? RPTREE_NODE_LEAF_ITEM_SIZE : RPTREE_NODE_CHILD_ITEM_SIZE);

    FileRange *range2 = [FileRange rangeWithPosition:filePosition byteCount:bytesRequired];
    NSData *data2 = [self.bufferedReader dataForRange:range2];
    LittleEndianByteBuffer *byteBuffer2 =
            [LittleEndianByteBuffer littleEndianByteBufferWithData:data2 littleEndian:self.littleEndian];

    if (isLeaf) {
        for (int i = 0; i < count; i++) {
            RPTLeafItem *item = [[[RPTLeafItem alloc] init] autorelease];
            item.startChrom = [byteBuffer2 nextInt];
            item.startBase = [byteBuffer2 nextInt];
            item.endChrom = [byteBuffer2 nextInt];
            item.endBase = [byteBuffer2 nextInt];
            item.dataOffset = [byteBuffer2 nextLong];
            item.dataSize = [byteBuffer2 nextLong];
            [items addObject:item];

        }
        return [[[RPTreeNode alloc] initWithItems:items] autorelease];
    }
    else { // non-leaf
        for (int i = 0; i < count; i++) {

            RPTChildItem *item = [[[RPTChildItem alloc] init] autorelease];
            item.startChrom = [byteBuffer2 nextInt];
            item.startBase = [byteBuffer2 nextInt];
            item.endChrom = [byteBuffer2 nextInt];
            item.endBase = [byteBuffer2 nextInt];
            item.childOffset = [byteBuffer2 nextLong];
            [items addObject:item];

        }
        return [[[RPTreeNode alloc] initWithItems:items] autorelease];
    }

}


@end


@implementation RPTItem {

}

- (NSString *)description {
    return [NSString stringWithFormat:@"RPTItem"];

}

- (BOOL)overlapsChr:(int)chrIdx startBase:(int)startBase endBase:(int)endBase {

    if (chrIdx > self.startChrom && chrIdx < self.endChrom) return YES;


    // Eliminate all cases outside of the interval.
    if ((chrIdx < self.startChrom || chrIdx > self.endChrom) ||
            (chrIdx == self.startChrom && endBase < self.startBase) ||
            (chrIdx == self.endChrom && startBase >= self.endBase))
        return NO;
    else
        return YES;


}

@end

@implementation RPTreeNode {

}

- (void)dealloc {
    [_items release];
    [super dealloc];
}

- (RPTreeNode *)initWithItems:(NSMutableArray *)array {

    self = [super init];
    if (nil != self) {

        self.items = array;

        int minChromId = NSIntegerMax;
        int maxChromId = 0;
        int minStartBase = NSIntegerMax;
        int maxEndBase = 0;

        for (RPTItem *item in array) {
            minChromId = MIN(minChromId, item.startChrom);
            maxChromId = MAX(maxChromId, item.endChrom);
            minStartBase = MIN(minStartBase, item.startBase);
            maxEndBase = MAX(maxEndBase, item.endBase);
        }

        self.startChrom = minChromId;
        self.endChrom = maxChromId;
        self.startBase = minStartBase;
        self.endBase = maxEndBase;
    }
    return self;
}


@end


@implementation RPTChildItem {

}


- (void)dealloc {
    self.childNode = nil;
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (nil != self) {
        self.isLeaf = NO;
    }
    return self;
}

- (NSString *)description {

    return [NSString stringWithFormat:@"RPTChildItem %d  %d  %d  %d", self.startChrom, self.startBase, self.endChrom, self.endBase];

}

@end


@implementation RPTLeafItem {

}


- (id)init {
    self = [super init];
    if (nil != self) {
        self.isLeaf = YES;
    }
    return self;
}


- (NSString *)description {

    return [NSString stringWithFormat:@"RPTChildItem %d  %d  %d  %d", self.startChrom, self.startBase, self.endChrom, self.endBase];

}

@end


@implementation RPTreeHeader {

}
- (RPTreeHeader *)initWithBuffer:(LittleEndianByteBuffer *)byteBuffer {


    self = [super init];
    if (nil != self) {

        int magic = [byteBuffer nextInt];

        // check for a valid B+ Tree Header
        if (!(magic == RPTREE_MAGIC_LTH || magic == RPTREE_MAGIC_HTL)) {
            return false;
            // TODO -- error
        }

        // Get mChromosome B+ header information
        self.magic = magic;
        self.blockSize = [byteBuffer nextInt];
        self.itemCount = [byteBuffer nextLong];
        self.startChromID = [byteBuffer nextInt];
        self.startBase = [byteBuffer nextInt];
        self.endChromID = [byteBuffer nextInt];
        self.endBase = [byteBuffer nextInt];
        self.endFileOffset = [byteBuffer nextLong];
        self.itemsPerSlot = [byteBuffer nextInt];
        self.reserved = [byteBuffer nextInt];

    }

    return self;

}
@end