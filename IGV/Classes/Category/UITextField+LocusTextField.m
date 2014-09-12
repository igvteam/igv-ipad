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
// Created by turner on 5/21/14.
//

#import "UITextField+LocusTextField.h"
#import "GenomeManager.h"
#import "Cytoband.h"
#import "NSArray+Cytoband.h"
#import "IGVHelpful.h"
#import "UIApplication+IGVApplication.h"
#import "IGVContext.h"

@implementation UITextField (LocusTextField)
- (void)updateWithScrollThreshold:(RSVScrollThreshold)scrollThreshold chromosomeName:(NSString *)chromosomeName start:(long long int)start end:(long long int)end {

    RootContentController *rootContentController = [UIApplication sharedRootContentController];
    if ([rootContentController.rootScrollView willDisplayEntireChromosomeName:chromosomeName start:start end:end]) {
        self.text = [NSString stringWithFormat:@"chr%@", [IGVContext sharedIGVContext].chromosomeName];
    }

    NSArray *chromosomeExtent = [[GenomeManager sharedGenomeManager] chromosomeExtentWithChromosomeName:chromosomeName];
    switch (scrollThreshold) {

        case RSVScrollThresholdUnevaluated:
        case RSVScrollThresholdNone:
            break;

        case RSVScrollThresholdLeftAndRight:
        {
            start = [chromosomeExtent start];
            end   = [chromosomeExtent end];
        }
            break;

        case RSVScrollThresholdRight:
        {
            end = [chromosomeExtent end];
        }
            break;

        case RSVScrollThresholdLeft:
        {
            start = [chromosomeExtent start];
        }
            break;

        default:
            return;
    }

    NSString *startString = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:(1 + start)]];
    NSString *endString   = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:end]];

    self.text = [NSString stringWithFormat:@"chr%@:%@-%@", chromosomeName, startString, endString];

}
@end