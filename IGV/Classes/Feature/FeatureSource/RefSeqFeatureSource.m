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
// Created by turner on 1/8/13.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "RootContentController.h"
#import "TrackView.h"
#import "AlignmentRenderer.h"
#import "RefSeqTrackView.h"
#import "RefSeqTrackController.h"
#import "RefSeqFeatureSource.h"
#import "URLDataLoader.h"
#import "IGVContext.h"
#import "GenomeManager.h"
#import "FileRange.h"
#import "HttpResponse.h"
#import "Logging.h"
#import "FeatureInterval.h"
#import "IGVHelpful.h"
#import "FastaSequenceManager.h"
#import "GenomicInterval.h"
#import "FastaSequence.h"

@implementation RefSeqFeatureSource

@synthesize refSeqString = _refSeqString;
@synthesize start = _start;
@synthesize end = _end;

- (void)dealloc {
    self.refSeqString = nil;
    [super dealloc];
}

// Do we have sequence to cover the requested interval?
- (BOOL)hasSequenceForInterval:(FeatureInterval *)featureInterval {

    if (nil == self.refSeqString) {
        return false;
    }

    BOOL status = !(featureInterval.start < self.start || featureInterval.end > self.end);

    return status;
}

- (void)loadFeaturesForInterval:(FeatureInterval *)featureInterval completion:(LoadFeaturesCompletion)completion {

    FileRange *fileRange = [FileRange rangeWithPosition:featureInterval.start byteCount:[featureInterval length]];
    NSDictionary *currentGenomeStub = [[GenomeManager sharedGenomeManager] currentGenomeStub];

    NSString *fastaSeqFile = [currentGenomeStub objectForKey:kFastaSequenceFileKey];
    if (/*YES ||*/ !fastaSeqFile) {

        NSString *refSeqPath = [currentGenomeStub objectForKey:kSequenceLocationKey];

//        NSString *path = [NSString stringWithFormat:@"%@/chr%@.txt", refSeqPath, [IGVContext sharedIGVContext].chromosomeName];
        NSString *path = [NSString stringWithFormat:@"%@/chr%@.txt", refSeqPath, featureInterval.chromosomeName];

        [URLDataLoader loadDataWithPath:path forRange:fileRange completion:^(HttpResponse *httpResponse) {

            self.start = featureInterval.start;
            self.end   = featureInterval.end;

            if ([IGVHelpful errorDetected:httpResponse.error]) {

                ALog(@"ERROR %@", [(httpResponse.error) localizedDescription]);
                self.refSeqString = kReferenceSequenceFeatureSourceNetworkError;
            } else {

                self.refSeqString = [[[NSString alloc] initWithBytes:[httpResponse.receivedData bytes]
                                                              length:[httpResponse.receivedData length]
                                                            encoding:NSUTF8StringEncoding] autorelease];
            }

            completion();
        }];

    } else {

        GenomicInterval *genomicInterval = [[[GenomicInterval alloc] initWithChromosomeName:featureInterval.chromosomeName
                                                                                      start:featureInterval.start
                                                                                        end:featureInterval.end
                                                                                   features:nil] autorelease];

        FastaSequence *fastaSequence = [[FastaSequenceManager sharedFastaSequenceManager] fastaSequenceWithPath:fastaSeqFile indexFile:nil];

        [fastaSequence getSequenceWithGenomicInterval:genomicInterval continuation:^(NSString* sequenceString) {

            if (nil == sequenceString) {

                ALog(@"ERROR: Unable to retrieve fasta sequence");
                completion();
                return;
            }

            self.start = featureInterval.start;
            self.end   = featureInterval.end;

            self.refSeqString = sequenceString;

            completion();
        }];
    }

}

- (NSInteger)length {
    return (NSInteger)(self.end - self.start);
}

- (NSString *)description {

    NSString *ss = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:self.start]];
    NSString *ll = [[IGVHelpful sharedIGVHelpful].basesNumberFormatter stringFromNumber:[NSNumber numberWithLongLong:[self length]]];

    NSString *chromosomeName = [IGVContext sharedIGVContext].chromosomeName;
//    return [NSString stringWithFormat:@"chr%@ start %@ length %d string %d. %@", chromosomeName, ss, [self length], [self.refSeqString length], [self class]];
    return [NSString stringWithFormat:@"%@ start %@ length %@", [self class], ss, ll];

}

- (unichar)refSeqCharWithGenomicLocation:(long long int)genomicLocation {

    long long int index = genomicLocation - self.start;

    if (index < 0 || index >= [self.refSeqString length]) {
        return 0;
    }
    return [self.refSeqString characterAtIndex:(NSUInteger)index];
}

- (NSString *)refSeqLetterWithGenomicLocation:(long long int)genomicLocation {

    unichar result = [self refSeqCharWithGenomicLocation:genomicLocation];
    return (0 == result) ? nil : [NSString stringWithUnichar:result];

}

- (BOOL)referenceSequenceStringExists {

    return (nil != self.refSeqString);
}
@end