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
// Created by jrobinso on 7/30/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "BlockCompressedInputStream.h"
#import "URLDataLoader.h"
#import "HttpResponse.h"
#import "NSData+GZIP.h"

#import "BlockCompressedInputStreamConstants.h"
#import "Logging.h"
#import "FileRange.h"

@interface BlockCompressedInputStream ()
@property(nonatomic, retain) NSData *currentBlock;
- (void)readBlock;
@end

@implementation BlockCompressedInputStream {

    long long mBlockAddress;
    int mLastBlockLength;
    long long filePosition;
    long long fileMark;
    NSString *path;
    long long contentLength;
    NSUInteger mCurrentOffset;
}

@synthesize path;
@synthesize currentBlock;

- (void)dealloc {
    self.path = nil;
    self.currentBlock = nil;
    [super dealloc];
}

+ (id) streamForURL:(NSString *)aUrlString {
    return [[[self alloc] initForUrl:aUrlString] autorelease];
}

- (id)initForUrl:(NSString *)aUrlString {

    self = [super init];
    if (nil != self) {

        mBlockAddress = 0l;
        mLastBlockLength = 0;
        filePosition = 0;
        fileMark = 0;

        self.path = aUrlString;
        // TODO -- query for content length!
    }
    return self;
}

- (int)nextInt {

    union {
        int i;
        unsigned char b[4];
    } buffer;

    [self read:buffer.b offset:0 length:4];
    return buffer.i;

}

- (long long ) nextLong {

    union {
        long long  l;
        unsigned char b[8];
    } buffer;

    [self read:buffer.b offset:0 length:8];
    return buffer.l;
}

- (NSString *)nextString {

    unsigned char buffer[8192];  // <= TODO strings larger than this will be a problem

    int avail = [self available];
    if (avail == 0) {
        return nil;
    }

    BOOL done = NO;
    int len = 0;
    while (!done) {
        unsigned char *bytes = (unsigned char *)currentBlock.bytes;
        while (avail-- > 0) {
            unsigned char *c = &bytes[mCurrentOffset++];
            if (*c == 0) {
                done = YES;
                break;
            }
            else {
                buffer[len++] = *c;
            }
        }
        avail = [self available];   // Next block
    }

    return [[[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding] autorelease];
}

- (NSString *)nextLine {

     char eol = '\n';
     char eolCr = '\r';

    unsigned char buffer[8192];  // <= TODO strings larger than this will be a problem

    int avail = [self available];
    if (avail == 0) {
        return nil;
    }

    BOOL done = NO;
    BOOL foundCr = NO; // \r found flag
    int len = 0;
    while (!done) {
        unsigned char *bytes = (unsigned char *)currentBlock.bytes;
        while (avail-- > 0) {
            unsigned char *c = &bytes[mCurrentOffset++];
            if (*c == eol) {

                done = YES;
                break;
            }
            else if (foundCr) {
                --mCurrentOffset; // current char is not \n so put it back (line is terminated with /r
                done = true;
                break;
            }
            else if (*c == eolCr)  { // found \r -- a \n may or may not follow
                foundCr = true;
                continue;
            } else {
                buffer[len++] = *c;
            }
        }
        avail = [self available];   // Next block
    }

    return [[[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding] autorelease];

}

- (int)read:(unsigned char *)buffer offset:(int)offset length:(int)length {


    int originalLength = length;
    while (length > 0) {
        int avail = [self available];
        if (avail == 0) {
            if (originalLength == length) {
                return -1;  // EOF
            }
            break;
        }

        int copyLength = MIN(length, avail);

        unsigned char *bytes = (unsigned char *) currentBlock.bytes;
        for (int i = 0; i < copyLength; i++) {
            buffer[offset + i] = bytes[mCurrentOffset + i];
        }

        mCurrentOffset += copyLength;
        offset += copyLength;
        length -= copyLength;
    }
    return originalLength - length;
}


/**
* @return the number of bytes available in the current block
*/

- (int)available {
    if (currentBlock == nil || mCurrentOffset == currentBlock.length) {
        [self readBlock];
    }
    if (currentBlock == nil) {
        return 0;
    }
    return currentBlock.length - mCurrentOffset;
}

/**
* @return virtual file pointer that can be passed to seek() to return to the current position.  This is
* not an actual byte offset, so arithmetic on file pointers cannot be done to determine the distance between
* the two.
*/
- (long long)virtualFilePointer {


    if (mCurrentOffset == currentBlock.length) {
        // If current offset is at the end of the current block, file pointer should point
        // to the beginning of the next block.
        return [self makeFilePointerForBlockAddress:mBlockAddress + mLastBlockLength blockOffset:0];
    }
    return [self makeFilePointerForBlockAddress:mBlockAddress blockOffset:mCurrentOffset];
}


/**
* Seek to the given position in the file.  Note that pos is a special virtual file pointer,
* not an actual byte offset.
*
* @param pos virtual file pointer
*/
- (void)seekToPosition:(long long)virtualFilePointer {

    // Decode virtual file pointer
    // Upper 48 bits is the byte offset into the compressed stream of a block.
    // Lower 16 bits is the byte offset into the uncompressed stream inside the block.
    long long compressedOffset = (virtualFilePointer >> SHIFT_AMOUNT) & ADDRESS_MASK;
    int uncompressedOffset = virtualFilePointer & OFFSET_MASK;
    int available;
    if (mBlockAddress == compressedOffset && currentBlock != nil) {
        available = currentBlock.length;
    } else {
        filePosition = compressedOffset;
        mBlockAddress = compressedOffset;
        mLastBlockLength = 0;
        [self readBlock];
        available = [self available];
    }

    if (uncompressedOffset > available ||
            (uncompressedOffset == available && ![self eof])) {
        //throw new IOException("Invalid file pointer: " + pos);
    }

    mCurrentOffset = uncompressedOffset;
}

- (void)readBlock {

    // Read the block header
    HttpResponse *headerResponse = [URLDataLoader loadDataSynchronousWithPath:path
                                                                     forRange:[FileRange rangeWithPosition:filePosition
                                                                                                 byteCount:BLOCK_HEADER_LENGTH]];
    NSData *blockHeaderData = headerResponse.receivedData;

    NSInteger statusCode = headerResponse.statusCode;
    if (statusCode >= 300 || nil == blockHeaderData) {
        ALog(@"Error reading header");
    }

    int blockLength = [self unpackInt16Bytes:(Byte *)blockHeaderData.bytes offset:BLOCK_LENGTH_OFFSET] + 1;

    // Read the entire block (including the header, again, for convenience)
    HttpResponse *response = [URLDataLoader loadDataSynchronousWithPath:path
                                                               forRange:[FileRange rangeWithPosition:filePosition
                                                                                           byteCount:blockLength]];
    NSData *data = response.receivedData;
    filePosition += data.length;

    if (nil == data) {
        ALog(@"data(nil)");
    }

    [self inflateBlock:data compressedLength:blockLength];

    mBlockAddress += mLastBlockLength;
    mLastBlockLength = blockLength;
}


- (int)unpackInt16Bytes:(Byte *)buffer offset:(int)offset {


    return ((buffer[offset] & 0xFF) |
            ((buffer[offset + 1] & 0xFF) << 8));
}

- (int)unpackInt32Bytes:(char *)buffer offset:(int)offset {
    return ((buffer[offset] & 0xFF) |
            ((buffer[offset + 1] & 0xFF) << 8) |
            ((buffer[offset + 2] & 0xFF) << 16) |
            ((buffer[offset + 3] & 0xFF) << 24));
}

- (void)inflateBlock:(NSData *)compressedBlockData compressedLength:(int)compressedLength {

//    int uncompressedLength = [self unpackInt32Bytes:(char *)compressedBlockData.bytes offset:compressedLength - 4];
    (void)[self unpackInt32Bytes:(char *)compressedBlockData.bytes offset:compressedLength - 4];
    
//    self.currentBlock = [[[NSData alloc] initWithGzippedData:compressedBlockData] autorelease];
    self.currentBlock = [compressedBlockData gunzippedData];
    mCurrentOffset = 0;

}

- (BOOL)eof {

    // If the last remaining block is the size of the EMPTY_GZIP_BLOCK, this is the same as being at EOF.
    return (contentLength - (mBlockAddress + mLastBlockLength) == EMPTY_GZIP_BLOCK_LENGTH);
}

/**
* @param blockAddress File offset of start of BGZF block.
* @param blockOffset Offset into uncompressed block.
* @return Virtual file pointer that embodies the input parameters.
*/
- (long long)makeFilePointerForBlockAddress:(long long)blockAddress blockOffset:(int)blockOffset {
    if (blockOffset < 0) {
        // throw new IllegalArgumentException("Negative blockOffset " + blockOffset + " not allowed.");
    }
    else if (blockAddress < 0) {
        //  throw new IllegalArgumentException("Negative blockAddress " + blockAddress + " not allowed.");
    }
    else if (blockOffset > MAX_OFFSET) {
        // throw new IllegalArgumentException("blockOffset " + blockOffset + " too large.");
    }
    else if (blockAddress > MAX_BLOCK_ADDRESS) {
        // throw new IllegalArgumentException("blockAddress " + blockAddress + " too large.");
    }

    return blockAddress << SHIFT_AMOUNT | blockOffset;
}


- (void)reset {
    filePosition = fileMark;
}


/**
* @param stream Must be at start of file.  Throws RuntimeException if !stream.markSupported().
* @return true if the given file looks like a valid BGZF file.
*/
+ (BOOL)isValidPath:(NSString *)path {

    FileRange *headerByteRange = [FileRange rangeWithPosition:0
                                                    byteCount:BLOCK_HEADER_LENGTH];

    HttpResponse *headerResponse = [URLDataLoader loadDataSynchronousWithPath:path
                                                                     forRange:headerByteRange];

    int count = [headerResponse.receivedData length];

    BOOL success = [self isValidBlockHeader:headerResponse.receivedData];

    return count == BLOCK_HEADER_LENGTH && success;
}


+ (BOOL)isValidBlockHeader:(NSData *)data {

    unsigned char *buffer = (unsigned char *) data.bytes;

    return (buffer[0] == GZIP_ID1 &&
            (buffer[1] & 0xFF) == GZIP_ID2 &&
            (buffer[3] & GZIP_FLG) != 0 &&
            buffer[10] == GZIP_XLEN &&
            buffer[12] == BGZF_ID1 &&
            buffer[13] == BGZF_ID2);

}


@end