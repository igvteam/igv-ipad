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
//  FastaSequenceManager.m
//  IGV
//
//  Created by turner on 5/16/14.
//
//

#import "FastaSequenceManager.h"
#import "FastaSequence.h"

@implementation FastaSequenceManager

@synthesize fastaSequenceInstances = _fastaSequenceInstances;

- (void)dealloc {

    self.fastaSequenceInstances = nil;
    [super dealloc];
}

+ (FastaSequenceManager *)sharedFastaSequenceManager {

    static dispatch_once_t pred;
    static FastaSequenceManager *shared = nil;

    dispatch_once(&pred, ^{

        shared = [[FastaSequenceManager alloc] init];
    });

    return shared;
}

- (NSMutableDictionary *)fastaSequenceInstances {

    if (nil == _fastaSequenceInstances) {
        self.fastaSequenceInstances = [NSMutableDictionary dictionary];
    }

    return _fastaSequenceInstances;
}

-(FastaSequence *)fastaSequenceWithPath:(NSString *)path indexFile:(NSString *)indexFile {

    FastaSequence *fastaSequence = [self.fastaSequenceInstances objectForKey:path];

    if(!fastaSequence) {

        fastaSequence = [[[FastaSequence alloc] initWithPath:path indexFile:indexFile] autorelease];
        [self.fastaSequenceInstances setObject:fastaSequence forKey:path];
    }

    return fastaSequence;
}

@end
