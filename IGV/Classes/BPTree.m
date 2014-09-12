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

#import "BPTree.h"
#import "LittleEndianByteBuffer.h"


int const BPTREE_MAGIC_LTH = 0x78CA8C91;
int const BPTREE_MAGIC_HTL = 0x918CCA78;
int const BPTREE_HEADER_SIZE = 32;

@interface BPTree ()
@end

@implementation BPTree {

}


- (void)dealloc {

    self.header = nil;
    self.dictionary = nil;
    [super dealloc];
}

- (BPTree *)initWithBuffer:(LittleEndianByteBuffer *)byteBuffer treeOffset:(long long)treeOffset {

    self = [super init];
    if (nil != self) {

        self.treeOffset = treeOffset; // File offset to beginning of tree

        self.header = [[[BPTreeHeader alloc] initWithBuffer:byteBuffer] autorelease];

        self.dictionary = [NSMutableDictionary dictionary];

        // Recursively walk tree to populate dictionary
        [self readTreeNode:byteBuffer offset:-1];

    }

    return self;
}


- (void)readTreeNode:(LittleEndianByteBuffer *)byteBuffer offset:(int)offset {

    if(offset >= 0) byteBuffer.position = offset;

    id node;

    u_char type = [byteBuffer nextByte];
    BOOL isLeaf = (type == (u_char) 1) ? YES : NO;

    u_char reserved = [byteBuffer nextByte];
    short count = [byteBuffer nextShort];

    const int keySize = self.header.keySize;


    if (isLeaf) {
        for (int i = 0; i < count; i++) {
            NSString *key = [byteBuffer nextBytesAsString:keySize];
            NSNumber *chromId = [NSNumber numberWithInt:[byteBuffer nextInt]];
            int chromSize = [byteBuffer nextInt];
            [self.dictionary setObject: chromId forKey: key];

        }
    }
    else { // non-leaf
        for (int i = 0; i < count; i++) {
            long long childOffset = [byteBuffer nextLong];
            long long bufferOffset = childOffset - self.treeOffset;
            [self readTreeNode:byteBuffer offset:bufferOffset];
        }
    }

}

@end


@implementation BPTreeHeader {

}


- (BPTreeHeader *)initWithBuffer:(LittleEndianByteBuffer *)byteBuffer {

    self = [super init];
    if (nil != self) {

        int magic = [byteBuffer nextInt];

        if (magic != BPTREE_MAGIC_LTH) {
//            return false;
            self = nil;
            return self;
        }

        // Get mChromosome B+ header information
        self.blockSize = [byteBuffer nextInt];
        self.keySize = [byteBuffer nextInt];
        self.valSize = [byteBuffer nextInt];
        self.itemCount = [byteBuffer nextLong];
        self.reserved = [byteBuffer nextLong];

    }

    return self;
}
@end



