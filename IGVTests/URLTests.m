//
// Created by turner on 7/24/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <SenTestingKit/SenTestingKit.h>
#import "Logging.h"

@interface URLTests : SenTestCase
@end

@implementation URLTests

- (void)testURLDecomposition {

    NSURL *url = [NSURL URLWithString:@"http://www.broadinstitute.org/igvdata/1KG/pilot2Bams/NA12878.SLX.bam"];
    STAssertNotNil(url, nil);

    ALog(@"host+path %@%@", [url host], [url path]);
}

@end