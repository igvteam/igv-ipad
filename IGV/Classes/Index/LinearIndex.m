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
// Created by jrobinso on 7/27/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "LinearIndex.h"
#import "LittleEndianByteBuffer.h"
#import "ChrIndex.h"


static int SEQUENCE_DICTIONARY_FLAG = 0x8000;

@interface LinearIndex ()

- (id)initWithBytes:(LittleEndianByteBuffer *)buffer withError:(NSError **)error;

- (void)readHeader:(LittleEndianByteBuffer *)buffer;


@end

@implementation LinearIndex {
    NSInteger version;
    NSMutableDictionary *properties;
}

@synthesize chrIndices = _chrIndices;
@synthesize properties = _properties;

- (void)dealloc {

    self.chrIndices = nil;
    self.properties = nil;

    [super dealloc];
}

+ (id)indexFromBytes:(LittleEndianByteBuffer *)buffer withError:(NSError **)error {

    return [[[self alloc] initWithBytes:buffer withError:error] autorelease];

}

- (id)initWithBytes:(LittleEndianByteBuffer *)buffer withError:(NSError **)error {

    self = [super init];
    if (nil != self) {
        [self readHeader:buffer];

        NSUInteger nChromosomes = (NSUInteger)[buffer nextInt];
        self.chrIndices = [NSMutableDictionary dictionaryWithCapacity:nChromosomes];

        while (nChromosomes-- > 0) {
            ChrIndex *chrIdx = [ChrIndex indexFromBytes:buffer withError:error];
            [self.chrIndices setObject:chrIdx forKey:chrIdx.name];
        }
    }
    return self;
}


- (void)readHeader:(LittleEndianByteBuffer *)buffer {

    version = [buffer nextInt];

    [buffer nextString];   // indexedFile =
    [buffer nextLong]; // indexedFileSize =
    [buffer nextLong];  // indexedFileTS =
    [buffer nextString];  // indexedFileMD5 =
    int flags = [buffer nextInt];
    if (version < 3 && (flags & SEQUENCE_DICTIONARY_FLAG) == SEQUENCE_DICTIONARY_FLAG) {
        [self readSequenceDictionaryFromBytes:buffer];
    }

    if (version >= 3) {
        NSUInteger nProperties = (NSUInteger)[buffer nextInt];
        self.properties = [NSMutableDictionary dictionaryWithCapacity:nProperties];
        while (nProperties-- > 0) {
            NSString *key = [buffer nextString];
            NSString *value = [buffer nextString];
            [properties setObject:value forKey:key];
        }
    }
}

- (NSArray *)chromosomeNames {

    return self.chrIndices == nil ? nil : [self.chrIndices allKeys];

}


// Deprecate, not sure if/why we need to keep this.
- (void)readSequenceDictionaryFromBytes:(LittleEndianByteBuffer *)buffer {
    int size = [buffer nextInt];
    if (size < 0) {
        // TODO -- error
    }
    for (int x = 0; x < size; x++) {
        [buffer nextString];   // chr
        [buffer nextInt];      // size
    }

}


@end