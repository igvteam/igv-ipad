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



const long SHIFT_AMOUNT = 16;
const long ADDRESS_MASK = 0xFFFFFFFFFFFFL;
const int OFFSET_MASK = 0xffff;
const int MAX_COMPRESSED_BLOCK_SIZE = 64 * 1024;
const int BLOCK_HEADER_LENGTH = 18;

const long MAX_BLOCK_ADDRESS = ADDRESS_MASK;
const int MAX_OFFSET = OFFSET_MASK;

// Location in the gzip block of the total block size (actually total block size - 1)
const int BLOCK_LENGTH_OFFSET = 16;

// Number of bytes that follow the deflated data
const int BLOCK_FOOTER_LENGTH = 8;

const unsigned char GZIP_ID1 = 31;
const int GZIP_ID2 = 139;

// FEXTRA flag means there are optional fields
const int GZIP_FLG = 4;

// extra flags
const int GZIP_XFL = 0;

// length of extra subfield
const short GZIP_XLEN = 6;

// The deflate compression, which is customarily used by gzip
const char GZIP_CM_DEFLATE = 8;

// We don't care about OS because we're not doing line terminator translation
const int GZIP_OS_UNKNOWN = 255;

// The subfield ID
const unsigned char BGZF_ID1 = 66;
const unsigned char BGZF_ID2 = 67;

// subfield length in bytes
const unsigned char BGZF_LEN = 2;

const int EMPTY_GZIP_BLOCK_LENGTH = 28;
const char EMPTY_GZIP_BLOCK[EMPTY_GZIP_BLOCK_LENGTH] = {GZIP_ID1, (char) GZIP_ID2, GZIP_CM_DEFLATE, (char) GZIP_FLG,
        0, 0, 0, 0, (char) GZIP_XFL,
        (char) GZIP_OS_UNKNOWN, (char) GZIP_XLEN, 0, BGZF_ID1, BGZF_ID2, BGZF_LEN, 0,
        (char) (BLOCK_HEADER_LENGTH + BLOCK_FOOTER_LENGTH - 1 + 2), 0,
        3, 0,
        0, 0, 0, 0, // crc
        0, 0, 0, 0 // uncompressedSize
};

