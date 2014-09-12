//
//  RefSeqFeatureSourceTests.m
//  IGV
//
//  Created by turner on 5/19/14.
//
//

#import <SenTestingKit/SenTestingKit.h>
#import "RefSeqFeatureSource.h"
#import "FeatureInterval.h"
#import "GenomeManager.h"
#import "IGVContext.h"

@interface RefSeqFeatureSourceTests : SenTestCase
@end

@implementation RefSeqFeatureSourceTests

- (void)testLoadFeaturesForInterval {

    NSError *error = nil;
    BOOL success = [[GenomeManager sharedGenomeManager] loadGenomeStubsWithGenomePath:kGenomesFilePath error:&error];
    STAssertTrue(success, nil);
    STAssertNil(error, nil);

    NSString *chr = @"chr22";
    long long int startBase = 29565176;
    long long int   endBase = 29565216;

    FeatureInterval *featureInterval = [FeatureInterval intervalWithChromosomeName:chr start:29565176 end:29565216];
    STAssertNotNil(featureInterval, nil);

    IGVContext *igvContext = [IGVContext sharedIGVContext];
    STAssertNotNil(igvContext, nil);

    igvContext.chromosomeName = [[GenomeManager sharedGenomeManager].chromosomeNames objectForKey:chr];

    double locusOffsetComparison;
    [igvContext setWithLocusStart:startBase locusEnd:endBase locusOffsetComparisonBases:&locusOffsetComparison];

    RefSeqFeatureSource *refSeqFeatureSource = [[[RefSeqFeatureSource alloc] init] autorelease];
    STAssertNotNil(refSeqFeatureSource, nil);

    __block BOOL waitingForBlock = YES;
    [refSeqFeatureSource loadFeaturesForInterval:featureInterval completion:^() {

        STAssertTrue([@"CTTGTAAATCAACTTGCAATAAAAGCTTTTCTTTTCTCAA" isEqualToString:refSeqFeatureSource.refSeqString], nil);
        waitingForBlock = NO;
    }];

    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }

}

- (void)testRefSeqFeatureSourceCreation {

    RefSeqFeatureSource *refSeqFeatureSource = [[[RefSeqFeatureSource alloc] init] autorelease];
    STAssertNotNil(refSeqFeatureSource, nil);
}

- (void)testExample{
    STAssertTrue(YES, nil);
}

@end
