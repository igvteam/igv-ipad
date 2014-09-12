//
//  BWTests.m
//  IGV

//
//

#import <SenTestingKit/SenTestingKit.h>
#import "HttpResponse.h"
#import "BWReader.h"
#import "Logging.h"
#import "BWHeader.h"
#import "BWTotalSummary.h"
#import "BPTree.h"
#import "BWFeatureSource.h"


@interface BWTest : SenTestCase
@end

@implementation BWTest

- (void)testMetaData {

    NSString *path = @"http://www.broadinstitute.org/igvdata/ipad/bigWigExample.bw";
    //NSString *path = @"http://localhost/~jrobinso/Data/BW/bigWigExample.bw";

    BWReader *bwReader = [[[BWReader alloc] initWithPath:path] autorelease];
    [bwReader loadHeader];


    BWHeader *header = bwReader.header;
    STAssertNotNil(header, @"Header");

    STAssertEquals((short) 4, header.bwVersion, @"bwVersion");
    STAssertEquals((short) 10, header.nZoomLevels, @"nZoomLevels");
    STAssertEquals((long long) 344, header.chromTreeOffset, @"chromTreeOffset");
    STAssertEquals((long long) 393, header.fullDataOffset, @"fullDataOffset");
    STAssertEquals((long long) 15751049, header.fullIndexOffset, @"fullIndexOffset");

    // Summary data
    STAssertEquals((long long) 35106705, bwReader.totalSummary.basesCovered, @"basesCovered");
    STAssertEquals(0.0, bwReader.totalSummary.minVal, @"minVal");
    STAssertEquals(100.0, bwReader.totalSummary.maxVal, @"maxVal");
    STAssertEqualsWithAccuracy(77043134252.78125, bwReader.totalSummary.sumSquares, 1.0e-6, @"sumSquares");

    // chrom tree -- values taken from IGV java
    BPTreeHeader *ctHeader = bwReader.chromTree.header;
    STAssertEquals(1, ctHeader.blockSize, @"blockSize");
    STAssertEquals(5, ctHeader.keySize, @"keySize");
    STAssertEquals(8, ctHeader.valSize, @"valSize");
    STAssertEquals((long long) 1, ctHeader.itemCount, @"itemCount");

    // chrom lookup  == there's only 1 chromosomeName in this test file
    NSString *chrName = @"chr21";
    int chrIdx = [bwReader idxForChr:chrName];
    STAssertEquals(0, chrIdx, @"Chromosome index");


    // Total data count -- note this is the # of "sections", not the # of data points.  Verified with grep
    STAssertEquals(6857, bwReader.dataCount, @"dataCount");

    BigWigFileType type =  bwReader.type;
    STAssertEqualObjects(BigWig, type, @"Type");
    ALog(@"Finished testMetaData");
}

- (void)testLoadZoomdata {

    NSString *path = @"http://www.broadinstitute.org/igvdata/ipad/bigWigExample.bw";
    //NSString *path = @"http://localhost/~jrobinso/Data/BW/bigWigExample.bw";


    BWReader *bwReader = [[[BWReader alloc] initWithPath:path] autorelease];
    [bwReader loadHeader];

    BWHeader *header = bwReader.header;
    STAssertNotNil(header, @"Header");

    STAssertEquals((short) 4, header.bwVersion, @"bwVersion");
    STAssertEquals((short) 10, header.nZoomLevels, @"nZoomLevels");
    STAssertEquals((long long) 344, header.chromTreeOffset, @"chromTreeOffset");
    STAssertEquals((long long) 393, header.fullDataOffset, @"fullDataOffset");
    STAssertEquals((long long) 15751049, header.fullIndexOffset, @"fullIndexOffset");

    // Summary data -- values taken from IGV java.  Note maxVal does not agree with bigWigInfo (should be == 100)
    STAssertEquals((long long) 35106705, bwReader.totalSummary.basesCovered, @"basesCovered");
    STAssertEquals((float) 0, bwReader.totalSummary.minVal, @"minVal");
    STAssertEquals((float) 0, bwReader.totalSummary.maxVal, @"maxVal");
    STAssertEquals((float) 3.390625, bwReader.totalSummary.sumSquares, @"sumSquares");

    // chrom tree -- values taken from IGV java
    BPTreeHeader *ctHeader = bwReader.chromTree.header;
    STAssertEquals(1, ctHeader.blockSize, @"blockSize");
    STAssertEquals(5, ctHeader.keySize, @"keySize");
    STAssertEquals(8, ctHeader.valSize, @"valSize");
    STAssertEquals((long long) 1, ctHeader.itemCount, @"itemCount");


    // Total data count -- note this is the # of "sections", not the # of data points.  Verified with grep
    STAssertEquals(6857, bwReader.dataCount, @"dataCount");

    BigWigFileType type =  bwReader.type;
    STAssertEqualObjects(BigWig, type, @"Type");
    ALog(@"Finished testMetaData");
}



- (void)testBWSource {


}



@end
