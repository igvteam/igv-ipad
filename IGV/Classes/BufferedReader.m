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
// Created by James Robinson on 4/2/14.
//

#import "BufferedReader.h"
#import "FileRange.h"
#import "HttpResponse.h"
#import "URLDataLoader.h"


@interface BufferedReader ()
@property(nonatomic, copy) NSString *path;
@property(nonatomic) int bufferSize;
@property(nonatomic, retain) NSData *data;
@property(nonatomic, retain) FileRange *range;
@property(nonatomic) long long int contentLength;
@end

@implementation BufferedReader {

}

- (void)dealloc {
    [_path release];
    [_data release];
    [super dealloc];
}

- (id)initForPath:(NSString *)path contentLength:(long long int)contentLength bufferSize:(int)bufferSize {

    self = [super init];

    if (nil != self) {
        self.path = path;
        self.contentLength = contentLength;
        self.bufferSize = bufferSize;
    }

    return self;

}

- (NSData *)dataForRange:(FileRange *)requestedRange {

    if (nil == self.data || !((self.range.position <= requestedRange.position) &&
            ((self.range.position + self.range.byteCount) >= (requestedRange.position + requestedRange.byteCount)))) {

        int bufferSize = self.contentLength < 0 ? self.bufferSize : MIN(self.bufferSize, self.contentLength - requestedRange.position - 1);
        FileRange *loadRange = [FileRange rangeWithPosition:requestedRange.position byteCount:bufferSize];
        HttpResponse *response = [URLDataLoader loadDataSynchronousWithPath:self.path forRange:loadRange];

        // TODO -- handle error

        self.data = response.receivedData;
        self.range = loadRange;

    }

    long long int offset = requestedRange.position - self.range.position;
    NSRange bufferRange = NSMakeRange(offset, requestedRange.byteCount);
    return [self.data subdataWithRange:bufferRange];
}


@end