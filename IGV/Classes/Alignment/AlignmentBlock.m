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


#import "AlignmentBlock.h"
#import "Logging.h"

@interface AlignmentBlock ()
@property(nonatomic, assign) short readBase;
@property(nonatomic, assign) Alignment *alignment;
@end

@implementation AlignmentBlock

@synthesize start = _start;
@synthesize length = _length;
@synthesize readBase = _readBase;
@synthesize alignment = _alignment;

- (void) dealloc {

    self.alignment = nil;

    [super dealloc];
}

- (id)initWithAlignment:(Alignment *)alignment start:(long long int)start readBase:(short)readBase length:(short)length {
	
	self = [super init];
	
	if(nil != self) {

        self.alignment = alignment;
		self.start = start;
		self.readBase = readBase;
		self.length = length;
	}
	
	return self;
}

// Return the bases for this alignment block.  For effeciency we just return an offset into the parent alignment's bases array
- (char*) bases {

    char* ptr = [self.alignment bases];
    return &ptr[self.readBase];
}

// Return the base qualities for this alignment block.  For effeciency we just return an offset into the parent alignment's bases array
- (uint8_t*) qualities {

    uint8_t* ptr = [self.alignment qualities];
    return &ptr[self.readBase];
}

- (long long int)end {
	
	return self.start + self.length;
}

- (NSString *)description {
	
	return [NSString stringWithFormat:@"%@ start %lld end %lld length %d.", [self class], self.start, [self end], self.length];
}

@end
