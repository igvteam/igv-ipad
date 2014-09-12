//
//  FastaSequenceTests.m
//  IGV
//
//  Created by turner on 5/16/14.
//
//

#import <SenTestingKit/SenTestingKit.h>
#import "FastaSequenceManager.h"
#import "FastaSequence.h"
#import "Logging.h"
#import "GenomicInterval.h"

@interface FastaSequenceTests : SenTestCase
@end

@implementation FastaSequenceTests

- (void)testRepeatedAppendingOfString {

    NSUInteger howmany = 50000 * 2;
    NSString *acc = @"";

    while (howmany > [acc length]) {
        acc = [acc stringByAppendingString:@"a"];
    }

    ALog(@"acc %d", [acc length]);

}

- (void)testLoadFastaIndex {

    FastaSequenceManager *fastaSequenceManager = [FastaSequenceManager sharedFastaSequenceManager];
    STAssertNotNil(fastaSequenceManager, nil);

    NSString *path = @"http://www.broadinstitute.org/~helga/mm9.fasta";

    FastaSequence *fastaSequence = [fastaSequenceManager fastaSequenceWithPath:path indexFile:nil];
    STAssertNotNil(fastaSequence, nil);

    __block BOOL waitingForBlock = YES;
    [fastaSequence loadFastaIndexWithContinuation:^() {
        ALog(@"%@", fastaSequence.rawChromosomeNames);
        waitingForBlock = NO;
    }];

    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }

}

- (void)testGetSequence {

    FastaSequenceManager *fastaSequenceManager = [FastaSequenceManager sharedFastaSequenceManager];
    STAssertNotNil(fastaSequenceManager, nil);

    NSString *path = @"https://dl.dropboxusercontent.com/u/11270323/BroadInstitute/fastaSequence/hg19.fasta";

    FastaSequence *fastaSequence = [fastaSequenceManager fastaSequenceWithPath:path indexFile:nil];
    STAssertNotNil(fastaSequence, nil);

    NSString *chromosomeName = @"22";
    GenomicInterval *genomicInterval = [[[GenomicInterval alloc] initWithChromosomeName:chromosomeName
                                                                                  start:29565176
                                                                                    end:29565216
                                                                               features:nil] autorelease];
    STAssertNotNil(genomicInterval, nil);

    __block BOOL waitingForBlock = YES;
    [fastaSequence getSequenceWithGenomicInterval:genomicInterval continuation:^(NSString* sequenceString) {

        STAssertNotNil(sequenceString, nil);
        STAssertTrue([@"CTTGTAAATCAACTTGCAATAAAAGCTTTTCTTTTCTCAA" isEqualToString:sequenceString], nil);
        waitingForBlock = NO;
    }];

    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }


}

- (void)testReadSequence {

    FastaSequenceManager *fastaSequenceManager = [FastaSequenceManager sharedFastaSequenceManager];
    STAssertNotNil(fastaSequenceManager, nil);

    NSString *path = @"https://dl.dropboxusercontent.com/u/11270323/BroadInstitute/fastaSequence/hg19.fasta";

    FastaSequence *fastaSequence = [fastaSequenceManager fastaSequenceWithPath:path indexFile:nil];
    STAssertNotNil(fastaSequence, nil);

    NSString *chromosomeName = @"22";
    __block BOOL waitingForBlock = YES;
    [fastaSequence readSequenceWithChromosome:chromosomeName
                                   queryStart:29565176
                                     queryEnd:29565216
                                 continuation:^(NSString* sequenceString) {

                                     STAssertNotNil(sequenceString, nil);
                                     STAssertTrue([@"CTTGTAAATCAACTTGCAATAAAAGCTTTTCTTTTCTCAA" isEqualToString:sequenceString], nil);
                                     waitingForBlock = NO;
                                 }];


    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }


}

- (void)testFastaSequenceCreation {

    FastaSequenceManager *fastaSequenceManager = [FastaSequenceManager sharedFastaSequenceManager];
    STAssertNotNil(fastaSequenceManager, nil);

    NSString *path = nil;

    path = @"https://dl.dropboxusercontent.com/u/11270323/BroadInstitute/fastahg19/hg19.fa";
    FastaSequence *fastahg19 = [fastaSequenceManager fastaSequenceWithPath:path indexFile:nil];
    STAssertNotNil(fastahg19, nil);
    STAssertNotNil(fastahg19.path, nil);
    STAssertNotNil(fastahg19.indexFile, nil);

//    ALog(@"%@", fastaSequenceManager.fastaSequenceInstances);

    path = @"http://igv.broadinstitute.org/genomes/seq/mm10/mm10.fa";
    FastaSequence *fastamm10 = [fastaSequenceManager fastaSequenceWithPath:path indexFile:nil];
    STAssertNotNil(fastamm10, nil);
    STAssertNotNil(fastamm10.path, nil);
    STAssertNotNil(fastamm10.indexFile, nil);

//    ALog(@"%@", fastaSequenceManager.fastaSequenceInstances);
}

- (void)testExample {
    STAssertTrue(YES, nil);
}

@end
