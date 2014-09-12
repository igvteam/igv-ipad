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



#import "FloatArray.h"


@interface FloatArray ()
- (id)initWithCapacity:(int)aCapacity;

@end

@implementation FloatArray {

    int nPts;
    int capacity;
    float *elements;
}


- (void)dealloc {

    if (elements != nil) {
        free(elements);
    }

    [super dealloc];
}


+ (id)arrayWithCapacity:(int)aCapacity {

    return [[[self alloc] initWithCapacity:aCapacity] autorelease];

}

- (id)initWithCapacity:(int)aCapacity {

    self = [super init];
    if (nil != self) {
        capacity = aCapacity;
        nPts = 0;
        elements = malloc(aCapacity * sizeof(float));
    }
    return self;
}

- (int)count {
    return nPts;
}

- (void)addFloat:(float)f {

    if (nPts == capacity) {
        int newCapacity = (capacity * 3) / 2 + 1;
        float *newElements = malloc(newCapacity * sizeof(float));
        memcpy(newElements, elements, capacity * sizeof(float));

        free(elements);
        elements = newElements;
        capacity = newCapacity;
    }

    elements[nPts] = f;
    nPts++;

}

- (float)floatAtIndex:(int)i {

    if (i < nPts) {
        return elements[i];
    }
    else {
        return NAN;
    }
}


@end

