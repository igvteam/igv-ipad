#import "BWZoomLevelHeader.h"//
// Created by James Robinson on 3/31/14.
//

#import <SenTestingKit/SenTestingKit.h>
#import "BWReader.h"
#import "BWFeatureSource.h"
#import "RPTree.h"
#import "FeatureInterval.h"
#import "IGVContext.h"
#import "WIGFeature.h"
#import "FeatureList.h"


@interface BWFeatureSourceTests : SenTestCase
@end


@implementation BWFeatureSourceTests

- (void)testZoomLevels {

    NSString *path = @"http://www.broadinstitute.org/igvdata/ipad/bigWigExample.bw";
    //NSString *path = @"http://localhost/~jrobinso/Data/BW/bigWigExample.bw";


    BWFeatureSource *bwFeatureSource = [[[BWFeatureSource alloc] initWithFilePath:path] autorelease];
    [bwFeatureSource.reader loadHeader];


    double oneMB = 1000000;
    BWZoomLevelHeader *zoomLevelHeader = [bwFeatureSource zoomLevelForScale:oneMB];
    STAssertNotNil(zoomLevelHeader, @"Zoom level header");
    STAssertEquals(7, zoomLevelHeader.index, @"Zoom level index");
}


- (void)testHeader {

    NSString *path = @"http://hgdownload.cse.ucsc.edu/goldenPath/hg19/encodeDCC/wgEncodeBroadHistone/wgEncodeBroadHistoneGm12878H3k4me2StdSig.bigWig";
    //NSString *path = @"http://localhost/~jrobinso/Data/BW/bigWigExample.bw";


    BWFeatureSource *bwFeatureSource = [[[BWFeatureSource alloc] initWithFilePath:path] autorelease];
    [bwFeatureSource.reader loadHeader];


    double oneKB = 100;
    BWZoomLevelHeader *zoomLevelHeader = [bwFeatureSource zoomLevelForScale:oneKB];
    STAssertNotNil(zoomLevelHeader, @"Zoom level header");
    STAssertEquals(0, zoomLevelHeader.index, @"Zoom level index");

    NSArray *chrNames = bwFeatureSource.chromosomeNames;
    int cnt = [chrNames count];
    STAssertEquals(23, cnt, @"Chromsome names");

    RPTree *rpTree = [bwFeatureSource.reader rpTreeAtOffset:zoomLevelHeader.indexOffset];

    NSMutableArray *leafItems = [NSMutableArray array];

    int chrIdx = 10;
    int startBase = 10000000;
    int endBase = 20000000;
    [rpTree findLeafItemsOverlappingChr:chrIdx startBase:startBase endBase:endBase items:leafItems];

    STAssertTrue([leafItems count] > 0, @"rpTree");
    for (RPTLeafItem *item in leafItems) {
        int startChr = item.startChrom;
        int endChr = item.endChrom;

    }
}

- (void)testLoadFeatures {

    NSString *path = @"http://www.broadinstitute.org/igvdata/ipad/bigWigExample.bw";
    //NSString *path = @"http://localhost/~jrobinso/Data/BW/bigWigExample.bw";
    NSString *chr = @"chr21";
    int startBase = 19168957;
    int endBase = 19170640;

    double locusOffsetComparison;
    IGVContext *igvContext = [IGVContext sharedIGVContext];
    igvContext.chromosomeName = chr;
    [igvContext setWithLocusStart:startBase locusEnd:endBase locusOffsetComparisonBases:&locusOffsetComparison];


    double bpPerPixel = 1 / [[IGVContext sharedIGVContext] pointsPerBase ];

    BWFeatureSource *bwFeatureSource = [[[BWFeatureSource alloc] initWithFilePath:path] autorelease];
    [bwFeatureSource.reader loadHeader];

    FeatureInterval *featureInterval = [FeatureInterval intervalWithChromosomeName:chr start:startBase end:endBase];

    __block BOOL waitingForBlock = YES;

    [bwFeatureSource loadFeaturesForInterval:featureInterval completion:^() {
        waitingForBlock = NO;
    }];

    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }

    igvContext.chromosomeName = chr;
    [igvContext setWithLocusStart:startBase locusEnd:endBase locusOffsetComparisonBases:&locusOffsetComparison];
    FeatureList *featureList = [bwFeatureSource featuresForFeatureInterval:featureInterval];
    STAssertNotNil(featureList, @"featureList");

    // Count the # of features actually in the requested interval
    int count = 0;
    for(WIGFeature *feature in featureList.features) {
        if(feature.end >= startBase && feature.start < endBase) count++;
    }

    STAssertEquals(337, count, @"Feature count");

}


- (void)testLoadZoom {

    NSString *path = @"http://www.broadinstitute.org/igvdata/ipad/bigWigExample.bw";
    //NSString *path = @"http://localhost/~jrobinso/Data/BW/bigWigExample.bw";
    NSString *chr = @"chr21";
    int startBase = 18728264;
    int endBase = 26996291;

    double locusOffsetComparison;
    IGVContext *igvContext = [IGVContext sharedIGVContext];
    igvContext.chromosomeName = chr;
    [igvContext setWithLocusStart:startBase locusEnd:endBase locusOffsetComparisonBases:&locusOffsetComparison];


    double bpPerPixel = 1 / [[IGVContext sharedIGVContext] pointsPerBase ];

    BWFeatureSource *bwFeatureSource = [[[BWFeatureSource alloc] initWithFilePath:path] autorelease];
    [bwFeatureSource.reader loadHeader];

    FeatureInterval *featureInterval = [FeatureInterval intervalWithChromosomeName:chr start:startBase end:endBase];

    __block BOOL waitingForBlock = YES;

    [bwFeatureSource loadFeaturesForInterval:featureInterval completion:^() {
        waitingForBlock = NO;
    }];

    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }

    igvContext.chromosomeName = chr;
    [igvContext setWithLocusStart:startBase locusEnd:endBase locusOffsetComparisonBases:&locusOffsetComparison];
    FeatureList *featureList = [bwFeatureSource featuresForFeatureInterval:featureInterval];
    STAssertNotNil(featureList, @"featureList");

    // Count the # of features actually in the requested interval
    int count = 0;
    for(WIGFeature *feature in featureList.features) {
        if(feature.end >= startBase && feature.start < endBase) count++;
    }

    STAssertEquals(324, count, @"Feature count");

}


@end