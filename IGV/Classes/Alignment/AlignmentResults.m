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
// Created by jrobinso on 8/10/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "AlignmentRow.h"
#import "AlignmentBlock.h"
#import "AlignmentResults.h"
#import "Coverage.h"
#import "IGVHelpful.h"
#import "IGVContext.h"

@implementation AlignmentResults

@synthesize alignments = _alignments;
@synthesize coverage = _coverage;

- (void)dealloc {

    self.alignments = nil;
    self.coverage = nil;

    [super dealloc];
}

- (id)initWithAlignments:(NSMutableArray *)alignments coverage:(Coverage *)coverage {

    self = [super init];
    if (nil != self) {

        self.alignments = alignments;
        self.coverage = coverage;
    }

    return self;
}

#define kMaxLevels ((NSUInteger)1e5)
#define kMinAlignmentSpacing (5)

- (NSMutableArray *)packAlignmentsAndDiscardAlignments:(BOOL)discardAlignments {

    NSMutableArray *packedAlignments = [NSMutableArray array];

    @autoreleasepool {

        Alignment *first = (Alignment *) [self.alignments objectAtIndex:0];

        long long int firstStart = first.start;
        long long int bucketCount = ([IGVContext sharedIGVContext].end - firstStart) + 1;

        NSMutableArray *buckets = [NSMutableArray arrayWithCapacity:(NSUInteger) bucketCount];

        for (NSUInteger i = 0; i < bucketCount; i++) {
            [buckets insertObject:[NSNull null] atIndex:i];
        }

        // Insert first alignment to prime the pump
        [buckets replaceObjectAtIndex:0 withObject:[NSMutableArray arrayWithObject:first]];
        for (NSUInteger i = 1; i < [self.alignments count]; i++) {

            Alignment *alignment = [self.alignments objectAtIndex:i];

            NSUInteger bucketNumber = (NSUInteger)(alignment.start - firstStart);
            if (bucketNumber >= bucketCount) {
                continue;
            }

            if ([buckets objectAtIndex:bucketNumber] == [NSNull null]) {
                [buckets replaceObjectAtIndex:bucketNumber withObject:[NSMutableArray array]];
            }

            // Enqueue alignment
            [[buckets objectAtIndex:bucketNumber] insertObject:alignment atIndex:0];
        }

        int allocatedCount = 0;
        long long int nextStart = firstStart;
        while (allocatedCount < [self.alignments count] && [packedAlignments count] < kMaxLevels) {

            AlignmentRow *alignmentRow = [[[AlignmentRow alloc] init] autorelease];
            while (nextStart <= [IGVContext sharedIGVContext].end) {

                id thang = [NSNull null];

                NSUInteger index;
                NSInteger cnt = 0;
                while (thang == [NSNull null] && nextStart <= [IGVContext sharedIGVContext].end) {

                    ++cnt;

                    index = (NSUInteger)(nextStart - firstStart);
                    if ([buckets objectAtIndex:index] == [NSNull null]) {

                        ++nextStart;
                        continue;
                    }

                    thang = [buckets objectAtIndex:index];
                } 

                if (thang == [NSNull null]) {
                    continue;
                }

                // Dequeue alignment
                NSMutableArray *packedAlignmentBucket = (NSMutableArray *) thang;
                Alignment *alignment = (Alignment *) [[packedAlignmentBucket lastObject] retain];
                [packedAlignmentBucket removeLastObject];

                // If the bucket is empty, discard it and replace it with NULL
                if ([packedAlignmentBucket count] == 0) {
                    [buckets replaceObjectAtIndex:(NSUInteger)(nextStart - firstStart) withObject:[NSNull null]];
                }

                [alignmentRow addAlignment:alignment];
                [alignment release];

                nextStart = [alignmentRow end] + kMinAlignmentSpacing;

                ++allocatedCount;
            }

            if ([alignmentRow.alignments count] > 0) {

                // Enqueue currentRow
                [packedAlignments insertObject:alignmentRow atIndex:0];
            }

            nextStart = firstStart;
        } 
        
    }

    if (discardAlignments) {
        self.alignments = nil;
    }

    // sort each row by start
    for (AlignmentRow *alignmentRow in packedAlignments) {
        [alignmentRow sortViaAlignmentStart];
    }

    // reverse row order to match IGV desktop appearance
    [packedAlignments reverse];

    return packedAlignments;
}

@end