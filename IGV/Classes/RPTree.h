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

#import <Foundation/Foundation.h>

@class RPTreeHeader;
@class LittleEndianByteBuffer;
@class RPTreeNode;
@class BufferedReader;


@interface RPTree : NSObject
@property(nonatomic, retain) RPTreeHeader *header;
@property(nonatomic, retain) RPTreeNode *rootNode;


@property(nonatomic, retain) id path;


- (RPTree *)initWithOffset:(long long)fileOffset filesize:(long long)filesize path:(NSString *)path littleEndian:(BOOL)littleEndian;

- (void)load;

- (void)findLeafItemsOverlappingChr:(int)chrIdx startBase:(int)startBase endBase:(int)endBase items:(NSMutableArray *)leafItems;
@end


@interface RPTItem : NSObject
@property(nonatomic, assign) int startChrom;
@property(nonatomic, assign) int startBase;
@property(nonatomic, assign) int endChrom;
@property(nonatomic, assign) int endBase;

@property(nonatomic) BOOL isLeaf;

- (BOOL)overlapsChr:(int)chrIdx startBase:(int)startBase endBase:(int)endBase;
@end


@interface RPTreeNode : RPTItem

@property(nonatomic, retain) NSMutableArray *items;

- (RPTreeNode *)initWithItems:(NSMutableArray *)array;

@end

@interface RPTChildItem : RPTItem
@property(nonatomic, assign) long long childOffset;
@property(nonatomic, retain) id childNode;
@end


@interface RPTLeafItem : RPTItem
@property(nonatomic, assign) long long dataOffset;
@property(nonatomic, assign) long long dataSize;
@end


@interface RPTreeHeader : NSObject

@property(nonatomic) int blockSize;
@property(nonatomic) long long int itemCount;
@property(nonatomic) int startChromID;
@property(nonatomic) int startBase;
@property(nonatomic) int endChromID;
@property(nonatomic) int endBase;
@property(nonatomic) long long int endFileOffset;
@property(nonatomic) int itemsPerSlot;
@property(nonatomic) int reserved;
@property(nonatomic) int magic;

- (RPTreeHeader *)initWithBuffer:(LittleEndianByteBuffer *)buffer;

@end