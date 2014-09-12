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
//  Created by turner on 3/16/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "LabeledFeature.h"
#import "IGVHelpful.h"
#import "Logging.h"

@implementation LabeledFeature

@synthesize label = _label;

- (void)dealloc {

    self.label = nil;

    [super dealloc];
}

- (id)initWithStart:(long long int)start end:(long long int)end label:(NSString *)label {

    self = [super initWithStart:start end:end];

    if (nil != self) {

        if (nil == label || [@"" isEqualToString:label] || [@"." isEqualToString:label]) {
            self.label = @" ";
        } else {
            self.label = label;
        }
    }

    return self;
}

- (NSString *)description {

    NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];

    NSString *ss  = [numberFormatter stringFromNumber:[NSNumber numberWithLongLong:self.start]];
    NSString *ll  = [numberFormatter stringFromNumber:[NSNumber numberWithLongLong:[self length]]];

    return [NSString stringWithFormat:@"%@ start %@ length %@ label %@.", self, ss, ll, self.label];
}

@end
