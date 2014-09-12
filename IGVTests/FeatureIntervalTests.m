//
//  FeatureIntervalTests.m
//  IGV
//
//  Created by turner on 12/11/13.
//
//

#import <SenTestingKit/SenTestingKit.h>
#import "FeatureInterval.h"
#import "Logging.h"

@interface FeatureIntervalTests : SenTestCase

@end

@implementation FeatureIntervalTests

- (void)testFeatureIntervalContainsFeatureInterval
{
    long long int value = 512;
    long long int start = value;
    long long int end = 2 * value;
    FeatureInterval *container = [FeatureInterval intervalWithChromosomeName:@"7" start:start end:end];
    STAssertNotNil(container, nil);
//    ALog(@"%@", container);

    FeatureInterval *contained = [FeatureInterval intervalWithChromosomeName:@"7" start:(start + 128) end:(end - 128)];
    STAssertNotNil(contained, nil);
//    ALog(@"%@", contained);

    BOOL isContained = [container containsFeatureInterval:contained];
    STAssertTrue(isContained, nil);
}

@end
