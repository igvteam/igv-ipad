//
// Created by jrobinso on 8/10/12.
//
// To change the template use AppCode | Preferences | File Templates.
//



#import <SenTestingKit/SenTestingKit.h>
#import "IGVMath.h"

@interface IGVMathTests : SenTestCase
@end

@implementation IGVMathTests
- (void) testPercentile {

    int nPoints = 10000;
    NSUInteger array[nPoints];

    for (int i=0; i<nPoints; i++) {
        array[i] = 1 + (NSUInteger) arc4random_uniform(100);
    }


    NSUInteger value = [IGVMath percentileForArray:array size:nPoints percentile:95];

    STAssertEqualsWithAccuracy((float) value, 95.0f, 2.0f, @"95th percentile");

}

@end