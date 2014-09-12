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


#import "FileRange.h"

@implementation FileRange

@synthesize byteCount = _byteCount;
@synthesize position = _position;

- (id)initWithPosition:(long long int)position byteCount:(long long int)byteCount {

    self = [super init];
    if (nil != self) {
        _byteCount = byteCount;
        _position = position;
    }
    return self;
}

+ (FileRange *)rangeWithPosition:(long long int)position byteCount:(long long int)byteCount {

    FileRange *fileRange = [[[FileRange alloc] initWithPosition:position byteCount:byteCount] autorelease];

    return fileRange;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@. position %lld byteCount %lld", [self class], _position, _byteCount];
}


@end