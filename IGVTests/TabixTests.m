//
// Created by jrobinso on 7/30/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <SenTestingKit/SenTestingKit.h>
#import "BlockCompressedInputStream.h"
#import "TabixFeatureSource.h"
#import "FeatureInterval.h"
#import "FeatureList.h"
#import "LMResource.h"

@interface TabixTests : SenTestCase
@property(nonatomic, copy) NSString *path;
@end

@implementation TabixTests

@synthesize path = _path;

- (void)dealloc {

    self.path = nil;

    [super dealloc];
}

- (void)setUp {
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
    self.path = @"http://www.broadinstitute.org/igvdata/ipad/hg18_tabix_genes.bed.gz";
}

- (void)tearDown {
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void) testIsValidPath {

    BOOL isValid = [BlockCompressedInputStream isValidPath:self.path];

    STAssertTrue(isValid, nil);

}

- (void) testReadFeatures {

    LMResource *resource = [LMResource resourceWithName:nil filePath:self.path indexPath:nil];

    BaseFeatureSource *baseFeatureSource = [BaseFeatureSource featureSourceWithResource:resource];
    STAssertNotNil(baseFeatureSource, nil);

    TabixFeatureSource *tabixFeatureSource = (TabixFeatureSource *)baseFeatureSource;

    FeatureInterval *featureInterval = [FeatureInterval intervalWithChromosomeName:@"1" start:96959762 end:98283495];
    STAssertNotNil(featureInterval, nil);

    __block BOOL waitingForBlock = YES;

    [tabixFeatureSource loadFeaturesForInterval:featureInterval completion:^ () {
        waitingForBlock = NO;
    }];

    while (waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }

    FeatureList* featureList = [tabixFeatureSource featuresForFeatureInterval:featureInterval];
    STAssertNotNil(featureList, nil);

    STAssertTrue(3 == [featureList.features count], nil);

}

@end