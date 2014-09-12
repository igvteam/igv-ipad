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
// Created by turner on 10/23/13.
//

#import "CoverageMismatch.h"
#import "AlignmentBlock.h"

@implementation CoverageMismatch

@synthesize nucleotideLetter = _nucleotideLetter;
@synthesize quality = _quality;

- (void)dealloc {
    self.nucleotideLetter = nil;
    [super dealloc];
}

- (id)initWithAlignmentBlock:(AlignmentBlock *)alignmentBlock alignmentBlockIndex:(NSInteger)alignmentBlockIndex {
    
    self = [super init];
    if (nil != self) {

        self.nucleotideLetter = [NSString stringWithFormat:@"%c", [alignmentBlock bases][alignmentBlockIndex]];
        self.quality = [Alignment alphaFromQuality:[alignmentBlock qualities][alignmentBlockIndex]];
    }

    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@. nucleotide %@ quality %.3f", [self class], _nucleotideLetter, _quality];
}

@end