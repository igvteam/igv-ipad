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
// Created by jrobinso on 7/18/12.
//
// Class for converting a byte array into various numeric types and strings.
//  NOTE:  This class is not thread safe.
//
//

#import "LittleEndianByteBuffer.h"

const char eol = '\n';
const char eolCr = '\r';

@implementation LittleEndianByteBuffer {
    BOOL _littleEndian;
    NSUInteger _length;
}

@synthesize data = _data;
@synthesize position = _position;

- (void)dealloc {

    self.data = nil;
    
    [super dealloc];
}

- (id)initWithData:(NSData *)data {
    self = [self initWithData:data littleEndian:YES];
    return self;
}


- (id)initWithData:(NSData *)data littleEndian:(BOOL)lth {

    self = [super init];

    if (nil != self) {
        self.position = 0;
        _littleEndian = lth;
        _length = [data length];
        self.data = data;
    }

    return self;
}


- (u_char)nextByte {
    unsigned char *byteArray = (unsigned char *) [self.data bytes];
    return byteArray[_position++];
}

- (short)nextShort {
    
    unsigned char *byteArray = (unsigned char *) [self.data bytes];
    
    union {
        short i;
        unsigned char b[2];
    } buffer;
    
    if (_littleEndian) {
        buffer.b[0] = byteArray[_position];
        buffer.b[1] = byteArray[_position + 1];
    }
    else {
        buffer.b[0] = byteArray[_position + 1];
        buffer.b[1] = byteArray[_position];
    }

    _position += 2;
    return buffer.i;
}

- (int)nextInt {

    unsigned char *byteArray = (unsigned char *) [self.data bytes];

    union {
        int i;
        unsigned char b[4];
    } buffer;

    if (_littleEndian) {
        buffer.b[0] = byteArray[_position];
        buffer.b[1] = byteArray[_position + 1];
        buffer.b[2] = byteArray[_position + 2];
        buffer.b[3] = byteArray[_position + 3];
    }
    else {
        buffer.b[0] = byteArray[_position + 3];
        buffer.b[1] = byteArray[_position + 2];
        buffer.b[2] = byteArray[_position + 1];
        buffer.b[3] = byteArray[_position];
    }

    _position += 4;
    return buffer.i;

//    Byte *bytes = (Byte *) [self.data bytes];
//    int i =  *((int *) &bytes[_position]);
//    _position += 4;
//    return i;
//
}


- (long long int)nextLong {
    unsigned char *bytes = (unsigned char *) [self.data bytes];

    union {
        long long l;
        unsigned char b[8];
    } buffer;
    if (_littleEndian) {
        buffer.b[0] = bytes[_position];
        buffer.b[1] = bytes[_position + 1];
        buffer.b[2] = bytes[_position + 2];
        buffer.b[3] = bytes[_position + 3];
        buffer.b[4] = bytes[_position + 4];
        buffer.b[5] = bytes[_position + 5];
        buffer.b[6] = bytes[_position + 6];
        buffer.b[7] = bytes[_position + 7];
    }
    else {
        buffer.b[0] = bytes[_position + 7];
        buffer.b[1] = bytes[_position + 6];
        buffer.b[2] = bytes[_position + 5];
        buffer.b[3] = bytes[_position + 4];
        buffer.b[4] = bytes[_position + 3];
        buffer.b[5] = bytes[_position + 2];
        buffer.b[6] = bytes[_position + 1];
        buffer.b[7] = bytes[_position];
    }

    _position += 8;
    return buffer.l;
}

- (float)nextFloat {

    unsigned char *bytes = (unsigned char *) [self.data bytes];

    union {
        float f;
        unsigned char b[4];
    } buffer;

    if (_littleEndian) {
        buffer.b[0] = bytes[_position];
        buffer.b[1] = bytes[_position + 1];
        buffer.b[2] = bytes[_position + 2];
        buffer.b[3] = bytes[_position + 3];
    }
    else {
        buffer.b[0] = bytes[_position + 3];
        buffer.b[1] = bytes[_position + 2];
        buffer.b[2] = bytes[_position + 1];
        buffer.b[3] = bytes[_position];
    }

    _position += 4;
    return buffer.f;

}


- (double)nextDouble {

    unsigned char *bytes = (unsigned char *) [self.data bytes];

    union {
        double d;
        unsigned char b[8];
    } buffer;

    if (_littleEndian) {
        buffer.b[0] = bytes[_position];
        buffer.b[1] = bytes[_position + 1];
        buffer.b[2] = bytes[_position + 2];
        buffer.b[3] = bytes[_position + 3];
        buffer.b[4] = bytes[_position + 4];
        buffer.b[5] = bytes[_position + 5];
        buffer.b[6] = bytes[_position + 6];
        buffer.b[7] = bytes[_position + 7];
    }
    else {
        buffer.b[0] = bytes[_position + 7];
        buffer.b[1] = bytes[_position + 6];
        buffer.b[2] = bytes[_position + 5];
        buffer.b[3] = bytes[_position + 4];
        buffer.b[4] = bytes[_position + 3];
        buffer.b[5] = bytes[_position + 2];
        buffer.b[6] = bytes[_position + 1];
        buffer.b[7] = bytes[_position];
    }
    _position += 8;
    return buffer.d;
}

- (NSString *)nextString {

    unsigned char *bytes = (unsigned char *) [self.data bytes];
    long long int startPosition = _position;
    // Advance to the null terminator
    while (bytes[_position] != 0 && _position < _length) {
        _position++;
    }

    void *buffer = bytes + startPosition;
    NSUInteger len = (NSUInteger) (_position - startPosition);
    _position++;  // Gobble up null terminator

    NSString *string = [[[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding] autorelease];

    return string;
}

// Read the next "len" bytes and interpret as a string.
- (NSString *) nextBytesAsString: (int) len {

    unsigned char *bytes = (unsigned char *) [self.data bytes];
    long long int startPosition = _position;

    NSUInteger bufferLen = 0;
    for(long long int i = startPosition; i < startPosition + len; i++) {
        if(bytes[i] == 0) break;
        bufferLen++;
    }

    void *buffer = bytes + startPosition;

    _position += len;

    NSString *string = [[[NSString alloc] initWithBytes:buffer length:bufferLen encoding:NSASCIIStringEncoding] autorelease];

    return string;

}


/**
* Reads a whole line. A line is considered to be terminated by either a line feed ('\n'),
* carriage return ('\r') or carriage return followed by a line feed ("\r\n").
*
* @return  A String containing the contents of the line, excluding the line terminating
*          character, or null if the end of the stream has been reached
*
* @exception  IOException  If an I/O error occurs
* @
*/
- (NSString *)nextLine {

    unsigned char *bytes = (unsigned char *) [self.data bytes];
    NSString *line = nil;

    BOOL done = NO;
    BOOL foundCr = NO; // \r found flag
    while (!done) {
        long long int linetmpPos = _position;
        int bCnt = 0;

        // Find the eol
        int available = (int) (_length - _position);
        while ((available-- > 0)) {
            char c = bytes[linetmpPos++];
            if (c == eol) { // found \n
                done = true;
                break;
            } else if (foundCr) {  // previous char was \r
                --linetmpPos; // current char is not \n so put it back
                done = true;
                break;
            } else if (c == eolCr) { // found \r -- a \n may or may not follow
                foundCr = true;
                continue; // no ++bCnt
            }
            ++bCnt;
        }

        if (_position < linetmpPos) {

            void *buffer = bytes + _position;
            NSUInteger len = (NSUInteger) (linetmpPos - _position);
            line = [[[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding] autorelease];
            _position = linetmpPos;
        }
        if (_position == _length) {
            // EOF
            done = true;
        }
    }
    return line;

}

- (BOOL)isEOF {
    return _position >= _length;
}

- (int)available {
    return (int) (_length - _position - 1);
}

+ (id)littleEndianByteBufferWithData:(NSData *)data {
    return [[[self alloc] initWithData:data] autorelease];
}


+ (id)littleEndianByteBufferWithData:(NSData *)data littleEndian:(BOOL) lth {
    return [[[self alloc] initWithData:data littleEndian:lth] autorelease];
}

@end


