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
// Created by turner on 11/18/13.
//


#import "SEGCodec.h"
#import "GenomeManager.h"
#import "Logging.h"
#import "SEGFeature.h"
#import "Feature.h"
#import "IGVHelpful.h"

@interface SEGCodec ()
@end

@implementation SEGCodec

-(id)init {
    self = [super init];

    if (nil != self) {
    }

    return self;
}

/*
Track Name              chr     start       end         ignored         numeric value (ignored if non-numeric)
GenomeWideSNP_416532	1	       51598	   76187	     14	        -0.7116
GenomeWideSNP_416532	1	       76204	16022502	   8510	        -0.029
GenomeWideSNP_416532	1	    16026084	16026512	      6	        -2.0424
*/

- (Feature *)decodeLine:(NSString *)line sampleName:(NSString **)sampleName chromosome:(NSString **)chromosome error:(NSError **)error {

    NSMutableArray *tokens = [NSMutableArray arrayWithArray:[line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];

    NSUInteger tokenCount = [tokens count];
    if ([tokens count] < 4) {
        return nil;
    }

    NSUInteger index;

    index = 0;
    *sampleName = [tokens objectAtIndex:index];

    index = 1;
    *chromosome = [[GenomeManager sharedGenomeManager] chromosomeAliasForString:[tokens objectAtIndex:index]];

    index = 2;
    long long int start = [[tokens objectAtIndex:index] longLongValue];

    index = 3;
    long long int end = [[tokens objectAtIndex:index] longLongValue];

    if (start == end) {
        ++end;
    }

    if (end < start) {

        if (*error) *error = [IGVHelpful errorWithDetailString:[NSString stringWithFormat:@"%@. end %lld is less than start %lld", [self class], end, start]];
        return nil;
    }

//    index = 4;
//    NSInteger ignored = [[tokens objectAtIndex:index] integerValue];
//    NSInteger num_mark = [[tokens objectAtIndex:index] integerValue];

    index = tokenCount - 1;

    CGFloat value = [[tokens objectAtIndex:index] floatValue];
    return [[[SEGFeature alloc] initWithStart:start end:end value:value] autorelease];
}

+ (NSString *)fileSuffixKey {
    return @"seg";
}
@end