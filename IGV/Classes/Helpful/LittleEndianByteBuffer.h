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
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface LittleEndianByteBuffer : NSObject
- (id)initWithData:(NSData *)data;
- (id)initWithData:(NSData *)data littleEndian: (BOOL) lth;
@property(nonatomic) long long int position;
@property(nonatomic, retain) NSData *data;
- (short)nextShort;
- (int)nextInt;
- (long long int)nextLong;
- (NSString *)nextString;
- (NSString *)nextBytesAsString:(int)len;
- (NSString *)nextLine;
- (float)nextFloat;
- (double)nextDouble;
- (BOOL)isEOF;
- (int)available;
- (u_char)nextByte;
+ (id)littleEndianByteBufferWithData:(NSData *)data;
+ (id)littleEndianByteBufferWithData:(NSData *)data littleEndian:(BOOL)lth;
@end

