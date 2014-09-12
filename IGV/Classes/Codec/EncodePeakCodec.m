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
//  Created by turner on 2/28/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "EncodePeakCodec.h"
#import "GenomeManager.h"
#import "ExtendedFeature.h"
#import "EncodePeakFeature.h"
#import "IGVHelpful.h"

@implementation EncodePeakCodec

- (Feature *)decodeLine:(NSString *)aLine chromosome:(NSString **)chromosome error:(NSError **)error {

    NSMutableArray *tokens = [NSMutableArray arrayWithArray:[aLine componentsSeparatedByString:@"\t"]];

    if (3 > [tokens count]) {
        if (error) *error = [IGVHelpful errorWithDetailString:[NSString stringWithFormat:@"%@. token count %d < 3", [self class], [tokens count]]];
        return nil;
    }

    *chromosome = [[GenomeManager sharedGenomeManager] chromosomeAliasForString:[tokens objectAtIndex:0]];

    long long int start = [[tokens objectAtIndex:1] longLongValue];
    long long int end   = [[tokens objectAtIndex:2] longLongValue];

    if (start == end) {
        ++end;
    }

    if (end < start) {
        if (error) *error = [IGVHelpful errorWithDetailString:[NSString stringWithFormat:@"%@. end %lld is less than start %lld", [self class], end, start]];
        return nil;
    }

    NSString *name  = [tokens objectAtIndex:3];
    NSInteger score = [[tokens objectAtIndex:4] integerValue];
    FeatureStrandType strand = [ExtendedFeature strandTypeWithStrandString:[tokens objectAtIndex:5]];
    double value = [[tokens objectAtIndex:6] doubleValue];

    return [[[EncodePeakFeature alloc] initWithStart:start end:end name:name score:score strand:strand value:value] autorelease];

}

+ (NSString *)fileSuffixKey {
    return @"peak";
}

@end