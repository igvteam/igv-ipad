//
// Created by turner on 5/11/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <SenTestingKit/SenTestingKit.h>
#import "AsciiFeatureSource.h"
#import "FeatureInterval.h"
#import "Logging.h"
#import "FeatureList.h"
#import "URLDataLoader.h"
#import "HttpResponse.h"
#import "TDFFeatureSource.h"
#import "TDFReader.h"
#import "ParsingUtils.h"
#import "LMResource.h"
#import "Feature.h"
#import "LabeledFeature.h"
#import "IGVContext.h"
#import "GenomeManager.h"
#import "NSArray+Cytoband.h"
#import "Cytoband.h"

@interface FeatureSourceTests : SenTestCase
@property(nonatomic, retain) GenomeManager *genomeManager;
@end

@implementation FeatureSourceTests

@synthesize genomeManager = _genomeManager;

- (void)dealloc {

    self.genomeManager = nil;

    [super dealloc];
}

- (void)setUp {

    [super setUp];

    self.genomeManager = [GenomeManager sharedGenomeManager];
    NSError *error = nil;
    BOOL success = [self.genomeManager loadGenomeStubsWithGenomePath:kGenomesFilePath error:&error];
    ALog(@"%@ %@", [GenomeManager class], success ? @"loaded" : @"NOT-loaded");
}

- (void)tearDown {

    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testDataRetrievalForAllDataFormats {

//    NSString *path = @"http://www.broadinstitute.org/igvdata/Tumorscape/gz/Breast.seg.gz";
//    NSString *path = @"http://www.broadinstitute.org/igvdata/ipad/hg18_tabix_genes.bed.gz";
//    NSString *path = @"https://dl.dropboxusercontent.com/u/11270323/BroadInstitute/dataFormats/WIG/heart.SLC25A3.wig";
    NSString *path = @"https://dl.dropboxusercontent.com/u/11270323/BroadInstitute/dataFormats/Peak/wgEncodeBroadHistoneGm12878CtcfStdPk.peak";

    BaseFeatureSource *featureSource = [BaseFeatureSource featureSourceWithResource:[LMResource resourceWithName:nil filePath:path indexPath:nil]];
    STAssertNotNil(featureSource, nil);

    ALog(@"%@", [featureSource description]);

    // Entire chromosomeName 1
    NSArray *chromosomeExtent = [[GenomeManager sharedGenomeManager] chromosomeExtentWithChromosomeName:@"1"];
    FeatureInterval *featureInterval = [[[FeatureInterval alloc] initWithChromosomeName:@"1" start:[chromosomeExtent start] end:[chromosomeExtent end] zoomLevel:-1] autorelease];

    // Locus withing chromosomeName 12
//    FeatureInterval *featureInterval = [FeatureInterval intervalWithChromosomeName:@"12" start:97510176 end:97521926];
//    STAssertNotNil(featureInterval, nil);

    __block BOOL waitingForBlock = YES;

    [featureSource loadFeaturesForInterval:featureInterval completion:^() {
        waitingForBlock = NO;
    }];

    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }


    id anything = nil;
    anything = [featureSource featuresForFeatureInterval:featureInterval];
    if (nil != anything) {

        ALog(@"%@", anything);

        if ([anything isMemberOfClass:[FeatureList class]]) {

            FeatureList *featureList = anything;
            for (Feature *feature in featureList.features) {

                ALog(@"%@", [feature class]);
            }
        }

    };

}

- (void)testTabixFeatureSourceCreation {

    NSString *path = @"http://www.broadinstitute.org/igvdata/ipad/hg18_tabix_genes.bed.gz";

    LMResource *resource = [LMResource resourceWithName:nil filePath:path indexPath:nil];

    BaseFeatureSource *featureSource = [BaseFeatureSource featureSourceWithResource:resource];
    STAssertNotNil(featureSource, nil);

    FeatureInterval *featureInterval = [FeatureInterval intervalWithChromosomeName:@"1" start:96959762 end:98283495];
    STAssertNotNil(featureInterval, nil);

    __block BOOL waitingForBlock = YES;

    [featureSource loadFeaturesForInterval:featureInterval completion:^() {
        waitingForBlock = NO;
    }];

    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }

    FeatureList *featureList = [featureSource featuresForFeatureInterval:featureInterval];
    STAssertNotNil(featureList, nil);

    STAssertTrue(3 == [featureList.features count], nil);

}

- (void)testTDFFeatureSourceCreation {

//    NSString *path = @"http://www.broadinstitute.org/igvdata/encode/hg18/broadHistone/SignalGm12878Ctcf.tdf";
    NSString *path = @"http://www.broadinstitute.org/igvdata/encode/hg19/broadHistone/wgEncodeBroadHistoneGm12878ControlStdSig.wig.tdf";
    BaseFeatureSource *baseFeatureSource = [BaseFeatureSource featureSourceWithResource:[LMResource resourceWithName:nil filePath:path indexPath:nil]];
    STAssertNotNil(baseFeatureSource, nil);

//    FeatureInterval *featureInterval = [FeatureInterval intervalWithChromosomeName:@"16" start:0 end:88827254];
    FeatureInterval *featureInterval = [FeatureInterval intervalWithChromosomeName:@"16" start:20000000 end:40000000];
    STAssertNotNil(featureInterval, nil);

    TDFFeatureSource *tdfFeatureSource = (TDFFeatureSource *) baseFeatureSource;
    tdfFeatureSource.reader = [[[TDFReader alloc] initWithPath:tdfFeatureSource.filePath completion:^(HttpResponse *response) {

        tdfFeatureSource.trackName = [tdfFeatureSource.reader.trackNames objectAtIndex:0];

        if (tdfFeatureSource.reader.trackLine != nil && ![tdfFeatureSource.reader.trackLine isEqualToString:@""]) {

            tdfFeatureSource.trackProperties = [ParsingUtils parseTrackLine:tdfFeatureSource.reader.trackLine];
        }

    }] autorelease];

    __block BOOL waitingForBlock = YES;

    [tdfFeatureSource loadFeaturesForInterval:featureInterval completion:^() {
        waitingForBlock = NO;
    }];

    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }


    STAssertNotNil(tdfFeatureSource.reader, nil);

    FeatureList *featureList = [tdfFeatureSource featuresForFeatureInterval:featureInterval];

    if (nil != featureList) {

        ALog(@"%@", featureList);

        for (Feature *feature in featureList.features) {
            ALog(@"%@", [feature class]);
        }
    };

}

- (void)testSEGFeatureSourceCreation {

//    NSString *path = @"http://www.broadinstitute.org/igvdata/Tumorscape/gz/Acute%20lymphoblastic%20leukemia.seg.gz";
    NSString *path = @"http://www.broadinstitute.org/igvdata/Tumorscape/gz/Breast.seg.gz";
//    NSString *path = @"http://www.broadinstitute.org/igvdata/Tumorscape/gz/Colorectal.seg.gz";
//    NSString *path = @"http://www.broadinstitute.org/igvdata/Tumorscape/gz/Dedifferentiated%20liposarcoma.seg.gz";
//    NSString *path = @"http://www.broadinstitute.org/igvdata/Tumorscape/gz/Esophageal%20adenocarcinoma.seg.gz";
//    NSString *path = @"http://www.broadinstitute.org/igvdata/tcga/gbmsubtypes/Broad.080528.subtypes.seg.gz";

    BaseFeatureSource *featureSource = [BaseFeatureSource featureSourceWithResource:[LMResource resourceWithName:nil filePath:path indexPath:nil]];
    STAssertNotNil(featureSource, nil);

    NSArray *chromosomeExtent = [[GenomeManager sharedGenomeManager] chromosomeExtentWithChromosomeName:@"1"];
    FeatureInterval *featureInterval = [[[FeatureInterval alloc] initWithChromosomeName:@"1" start:[chromosomeExtent start] end:[chromosomeExtent end] zoomLevel:-1] autorelease];
    STAssertNotNil(featureInterval, nil);

    __block BOOL waitingForBlock = YES;

    [featureSource loadFeaturesForInterval:featureInterval completion:^() {
        waitingForBlock = NO;
    }];

    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }

    NSDictionary *segSamples = [featureSource featuresForFeatureInterval:featureInterval];
    STAssertNotNil(segSamples, nil);

    ALog(@"%@", [segSamples allKeys]);

}

//- (void)testIndexedFileFromGenomeSpace {
//
//    NSString *path = @"https://dm.genomespace.org/datamanager/file/Home/igvtest/ipad/hg18_refseq_genes.bed";
//    AsciiFeatureSource *featureSource = [AsciiFeatureSource featureSourceForPath:path];
//    STAssertNotNil(featureSource, nil);
//
//    // Load MUC1 locus  chr1:153,424,471-153,429,914
//    FeatureInterval *interval = [FeatureInterval intervalWithChromosomeName:@"1" start:153424471 end:153429914];
//    STAssertNotNil(featureSource, nil);
//
//    __block BOOL waitingForBlock = YES;
//
//    [featureSource loadFeaturesForInterval:interval completion:^() {
//        waitingForBlock = NO;
//    }];
//
//    while (waitingForBlock) {
//        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
//                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
//    }
//
//    FeatureList *featureList = [featureSource featuresForFeatureInterval:interval];
//    STAssertNotNil(featureList, nil);
//
//    NSArray *features = featureList.features;
//    BOOL found = NO;
//    for (LabeledFeature *feature in features) {
//        if ([feature.label isEqualToString:@"MUC1"]) {
//            found = YES;
//            break;
//        }
//    }
//
//    STAssertTrue(found, @"MUC1 found");
//
//}

@end