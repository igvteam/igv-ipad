//
//  BAMReaderTests.m
//  IGV
//
//  Created by turner on 10/21/13.
//
//

#import <SenTestingKit/SenTestingKit.h>
#import "BAMReader.h"
#import "IGVContext.h"
#import "URLDataLoader.h"
#import "HttpResponse.h"
#import "Logging.h"

@interface BAMReaderTests : SenTestCase
@end

@implementation BAMReaderTests

-(void)testBAMReader {

    NSString *path = @"http://1000genomes.s3.amazonaws.com/data/NA12878/high_coverage_alignment/NA12878.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130520.bam";
    BAMReader *bamReader = [[[BAMReader alloc] initWithPath:path] autorelease];

    STAssertNotNil(bamReader, nil);

    NSString *chr = @"1";

    NSUInteger start = 53305756;
    NSUInteger   end = 53307303;

    NSError *error = nil;
    AlignmentResults *alignmentResults = [bamReader fetchAlignmentsWithFeatureInterval:[[IGVContext sharedIGVContext] currentFeatureInterval] error:&error];
    STAssertNil(error, nil);

    STAssertNotNil(alignmentResults, nil);
}

-(void)testRetrieveDataFromWebService {

    NSString *urlString = @"http://su2c.broadinstitute.org/serveFiles.php?file=GMPxPPt4a4LK6BF/nV+8KRMSOAZsoMOGErrkw7iNG+6vg6mAZWXmfgOdZTRXQo71X193ht/ueKmXBT9ZxLwUerla+SO7YjQ/Yw9IWXCOGGxWmFGREAM2Qd+77xFG6RZKcyIWnsgj2m/2LUVO5kAxn88EaRPk/ZUEBHve6myNEWuWzpWbxRAvuZ1fpzCpkd8vdXbc/eUW0w138vvU3Avy9q4KdofhccRxX1vLpKlTi9p6DTBZfGbRU1gj3kN6lNi5AcMudwbDA63ux96DWuNVhpKqPu40iFfIGYhPtyMYWIY4v14b/V6lRcSgO6fnIZ+ZCDOLXYrDwO8E26hYnoAanuN+177GldT5O5gBf1msyqpcif/BxAuod2kYPNf7jiJeKCTPw/01Eu3U+OYBHL/leiOaX2cOQjFFhNfEarCd4Rflbun9ShG5+LjpNemRHImNesTgTdMW01srevH08Kf2IkHWWTCi211rtjM9ctuzqZHUBGB8PEVpEf3f2VNX7JxizCpCr0Uj7SgtYFJvFIx2MRupN01bWhJLBS9zV/sL9VzSlWA/SDcIe2BN80+MqSHm93jFIrsXSA7XAegV2BgKVdzvFtG96CZwwelw/tRuU4/r07Vh8BqwPZtns8IHJe38C4tUgBxcckhWe+TVTbeXQZAfCqczz1nI4Q3JwnBKhzM=&dataformat=.bam";

    HttpResponse *httpResponse = [URLDataLoader loadDataSynchronousWithPath:[urlString stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"]];
    STAssertNotNil(httpResponse, nil);

    NSData *data = [httpResponse receivedData];
    STAssertNotNil(data, nil);

    ALog(@"data %d", [data length]);

}

@end
