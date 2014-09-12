//
//  Created by turner on 2/12/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <SenTestingKit/SenTestingKit.h>
#import "LocusListItem.h"
#import "Logging.h"
#import "GenomeManager.h"
#import "Cytoband.h"
#import "NSArray+Cytoband.h"
#import "IGVHelpful.h"

@interface LocusListItemTests : SenTestCase
@property(nonatomic, retain) GenomeManager *genomeManager;
@end

@implementation LocusListItemTests

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

- (void)testLocusParsing {

    // NOTE: Do not support ":" in chromosomeName name
    NSArray *loci = [NSArray arrayWithObjects:@"chr18",
                                              @"15",
                                              @"chr18:4,000,000-4,000,150",
                                              @"15:4,000,000-4,000,150",
                                              @"8:102,728,809-102728810",
                                              @"abc:cba:12-21",
                                              @"abc:12",
                                              @"chr7:123456789",
                                              @"9:1,123",
                                              @"20:12,123",
                                              @"11:123,123,123",
                                              @"chr17:12-R1,123",
                                              @"17:1-2",
                                              @"5:1,234-4,321",
                                              @"2:1,234-4321",
                                              @"21:4321-1234",
                                              @"chr16",
                                              nil];

    for (NSString *locus in loci) {

        LocusListFormat locusListFormat = [locus formatWithGenomeManager:self.genomeManager];

        if (LocusListFormatInvalid == locusListFormat) {
            ALog(@"invalid locus %@", locus);
            continue;
        }

        STAssertTrue(LocusListFormatInvalid != locusListFormat, @"%@", locus);
    }

}

@end