//
//  GeneNameServiceControllerTests.m
//  IGV
//
//  Created by turner on 12/6/13.
//
//

#import <SenTestingKit/SenTestingKit.h>
#import "GenomeManager.h"
#import "GeneNameServiceController.h"
#import "Logging.h"

@interface GeneNameServiceControllerTests : SenTestCase
@property(nonatomic, retain) GenomeManager *genomeManager;
@end

@implementation GeneNameServiceControllerTests

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

-(void)testGeneNameServiceLookup {

    NSString *gene = @"BRCA1";

//    NSString *path = [NSString stringWithFormat:@"http://www.broadinstitute.org/webservices/igv/locus?genome=%@&name=%@", [GenomeManager sharedGenomeManager].currentGenomeName, gene];
//    NSArray *results = [GeneNameServiceController geneNameLookupResultsWithURLString:path];

    NSArray *results = [GeneNameServiceController locusForGene:gene];
    STAssertNotNil(results, nil);

    ALog(@"%@", results);

}

- (void)testNuthin
{
    STAssertTrue(NO, nil);
}

@end
