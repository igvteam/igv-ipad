#import "TDFDataset.h"//
// Created by jrobinso on 7/18/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <SenTestingKit/SenTestingKit.h>
#import "TDFReader.h"
#import "TDFFixedTile.h"
#import "TDFGroup.h"
#import "Logging.h"
#import "FileRange.h"
#import "URLDataLoader.h"
#import "LittleEndianByteBuffer.h"
#import "HttpResponse.h"
#import "ParsingUtils.h"
#import "FeatureCache.h"
#import "FeatureList.h"
#import "IGVHelpful.h"

@interface TDFReaderTests : SenTestCase
@end

@implementation TDFReaderTests

- (void)testReaderCreation {

    NSString *path = @"http://www.broadinstitute.org/igvdata/encode/hg18/broadHistone/SignalGm12878Ctcf.tdf";
    TDFReader *tdfReader = [[[TDFReader alloc] initWithPath:path completion:^(HttpResponse *response) {

        if ([IGVHelpful errorDetected:response.error]) {

            ALog(@"ERROR %@", [(response.error) localizedDescription]);
            return;
        }

    }] autorelease];
    STAssertNotNil(tdfReader, nil);

    ALog(@"%@", [tdfReader class]);

}

- (void)testReadMetadata {

    NSString *urlString = @"http://www.broadinstitute.org/igvdata/encode/hg18/broadHistone/SignalK562H3k4me3.tdf";


    __block BOOL waitingForBlock = YES;
    TDFReader *reader = [[[TDFReader alloc] initWithPath:urlString completion:^(HttpResponse *response) {

        if ([IGVHelpful errorDetected:response.error]) {
            STFail([(response.error) localizedDescription]);
            return;
        }
        waitingForBlock = NO;
    }] autorelease];


    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }


    NSInteger v = reader.version;
    STAssertEquals(v, 3, @"Version");
    STAssertTrue(reader.compressed, @"Compressed");

    NSMutableArray *sampleNames = reader.trackNames;
    NSInteger nTracks = sampleNames.count;
    STAssertEquals(nTracks, 1, @"Number of tracks");

    NSString *sampleName = [sampleNames objectAtIndex:0];
    STAssertEqualObjects(sampleName, @"SignalK562H3k4me3.wig.gz", @"sampleName");

    NSMutableSet *chrNames = reader.chromosomeNames;

    NSInteger nChromosomes = chrNames.count;
    STAssertTrue(nChromosomes == 24, @"Chromosome names");

    NSString *datasetName = @"/chr1/z0/mean";
    NSError *error = nil;
    TDFDataset *dataset = [reader loadDatasetForChromosome:@"chr1"
                                                      zoom:0
                                            windowFunction:@"mean"
                                                     error:&error];
    STAssertEqualObjects(dataset.name, datasetName, @"Dataset");

//    long * positions = dataset.tilePositions;
//    long pos = positions[0];

    id <TDFTile> tile = [reader tileForDataset:dataset number:0];
    NSInteger tileStart = [tile start];
    float tileSpan = ((TDFFixedTile *) tile).span;
    STAssertEquals(0, tileStart, @"TileStart");
//    STAssertEqualsWithAccuracy(tileSpan, 353213.90625f, 0.1f, @"TileSpan");
//
//    TDFGroup *rootGroup = [reader rootGroup];
//    NSDictionary *attributes = rootGroup.attributes;
//    NSArray *keys = attributes.allKeys;
//    for (NSString *k in keys) {
//        ALog(@"%@ -> %@", k, [attributes objectForKey:k]);
//    }

    ALog(@"Finished");
}

@end