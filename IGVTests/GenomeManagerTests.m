//
// Created by turner on 12/7/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <SenTestingKit/SenTestingKit.h>
#import "GenomeManager.h"

@interface GenomeManagerTests : SenTestCase
@end

@implementation GenomeManagerTests

- (void)testLoadGenomeStubsWithGenomePath {

    NSError *error = nil;
    BOOL success = [[GenomeManager sharedGenomeManager] loadGenomeStubsWithGenomePath:kGenomesFilePath error:&error];
    STAssertTrue(success, nil);
    STAssertNil(error, nil);

}

@end